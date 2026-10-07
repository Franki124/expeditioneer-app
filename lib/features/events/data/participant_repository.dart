import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/journal.dart';
import '../domain/quiz_question.dart';

import '../domain/participant.dart';

/// Thrown by [ParticipantRepository.joinEvent] when [displayName] is already
/// held by a different participant in the same event.
class DisplayNameTakenException implements Exception {
  const DisplayNameTakenException(this.displayName);

  final String displayName;
}

/// Normalizes a display name for per-event uniqueness comparison /
/// reservation-doc IDs: trimmed, lowercased, internal whitespace collapsed,
/// `/` stripped (Firestore doc IDs can't contain it).
String normalizeDisplayName(String name) {
  return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').replaceAll('/', '');
}

class ParticipantRepository {
  ParticipantRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _participantDoc(
    String eventId,
    String uid,
  ) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _nameReservationDoc(
    String eventId,
    String normalizedName,
  ) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('nameReservations')
        .doc(normalizedName);
  }

  /// Joins [eventId] as [uid], reserving [displayName] for this event so no
  /// other participant can hold the same (normalized) name — keeps the
  /// leaderboard unambiguous. Throws [DisplayNameTakenException] if another
  /// participant already holds it. A no-op if [uid] has already joined
  /// (rejoining under an already-held reservation is fine).
  Future<void> joinEvent({
    required String eventId,
    required String uid,
    required String displayName,
  }) async {
    final participantRef = _participantDoc(eventId, uid);
    final reservationRef = _nameReservationDoc(eventId, normalizeDisplayName(displayName));

    await _firestore.runTransaction((transaction) async {
      final participantSnapshot = await transaction.get(participantRef);
      if (participantSnapshot.exists) return;

      final reservationSnapshot = await transaction.get(reservationRef);
      if (reservationSnapshot.exists && reservationSnapshot.data()?['uid'] != uid) {
        throw DisplayNameTakenException(displayName);
      }

      transaction.set(participantRef, {
        'displayName': displayName,
        'joinedAt': FieldValue.serverTimestamp(),
        'collectedCount': 0,
        'totalPoints': 0,
        'lastScanAt': null,
        'completedAt': null,
      });
      transaction.set(reservationRef, {
        'uid': uid,
        'displayName': displayName,
        'reservedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<Participant?> watchParticipant(String eventId, String uid) {
    return _participantDoc(eventId, uid)
        .snapshots()
        .map((doc) => doc.exists ? Participant.fromDoc(doc) : null);
  }

  Stream<Set<String>> watchCollectedJournalIds(String eventId, String uid) {
    return _participantDoc(eventId, uid)
        .collection('scans')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Stream<List<Participant>> watchLeaderboard(String eventId, {int limit = 50}) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .orderBy('totalPoints', descending: true)
        .orderBy('lastScanAt')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Participant.fromDoc).toList());
  }

  /// Records a found quest. Works offline: the writes go into one batch,
  /// which Firestore keeps on the device and sends once there's a
  /// connection, so this returns as soon as the find is saved locally. (A
  /// transaction would need the server and fail with no signal.)
  ///
  /// The scan doc ID is the journal ID and the rules make it create-only, so
  /// a duplicate batch is rejected as a whole and never double-counts. The
  /// counters use increments rather than read-then-write so batches queued
  /// offline still add up when they sync.
  Future<void> recordScan({required String eventId, required String uid, required Journal journal}) async {
    final participantRef = _participantDoc(eventId, uid);
    final scanRef = participantRef.collection('scans').doc(journal.id);
    final eventRef = _firestore.collection('events').doc(eventId);
    final journalRef = eventRef.collection('journals').doc(journal.id);

    final scanSnapshot = await _readLocalFirst(scanRef);
    if (scanSnapshot?.exists ?? false) return;

    final participantSnapshot = await _readLocalFirst(participantRef);
    final eventSnapshot = await _readLocalFirst(eventRef);
    final currentCollected = (participantSnapshot?.data()?['collectedCount'] as num?)?.toInt() ?? 0;
    final journalCount = (eventSnapshot?.data()?['journalCount'] as num?)?.toInt() ?? 0;
    final newCollected = currentCollected + 1;
    // The device's clock, not serverTimestamp(): a find queued offline would
    // otherwise be stamped with the time it synced, which skews the
    // leaderboard's lastScanAt tie-break.
    final foundAt = Timestamp.now();

    final batch = _firestore.batch()
      ..set(scanRef, {'scannedAt': foundAt})
      ..update(participantRef, {
        'collectedCount': FieldValue.increment(1),
        'totalPoints': FieldValue.increment(journal.points),
        'lastScanAt': foundAt,
        if (journalCount > 0 && newCollected >= journalCount) 'completedAt': foundAt,
      })
      ..update(journalRef, {'scanCount': FieldValue.increment(1)});
    _commitInBackground(batch);
  }

  /// Journal IDs of every quiz this participant has *any* progress on
  /// (started but not necessarily finished) — used by the Journal tab to
  /// show a "Continue quiz" state distinct from "not yet found."
  Stream<Set<String>> watchInProgressQuizIds(String eventId, String uid) {
    return _participantDoc(eventId, uid)
        .collection('quizProgress')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Stream<QuizProgress?> watchQuizProgress(String eventId, String uid, String journalId) {
    return _participantDoc(eventId, uid)
        .collection('quizProgress')
        .doc(journalId)
        .snapshots()
        .map((doc) => doc.exists ? QuizProgress.fromDoc(doc) : null);
  }

  /// One-time fetch of every answer submitted for a finished quiz, keyed by
  /// question doc ID — used by the read-only review screen.
  Future<Map<String, QuizAnswerRecord>> getQuizAnswers(String eventId, String uid, String journalId) async {
    final snapshot =
        await _participantDoc(eventId, uid).collection('quizProgress').doc(journalId).collection('answers').get();
    return {for (final doc in snapshot.docs) doc.id: QuizAnswerRecord.fromDoc(doc)};
  }

  /// Records one answered quiz question. Same offline-safe batch shape as
  /// [recordScan]: no-op if this question was already answered (immutable
  /// `answers/{questionId}` doc), otherwise writes the answer and bumps the
  /// running `quizProgress` aggregate, and — if this was the quiz's last
  /// unanswered question — also does the participant-level bookkeeping
  /// [recordScan] does (creates `scans/{journalId}`, bumps
  /// `collectedCount`/`totalPoints`/`completedAt`), so every existing "is
  /// this collected" check keeps working for quizzes too.
  Future<void> submitQuizAnswer({
    required String eventId,
    required String uid,
    required Journal journal,
    required QuizQuestion question,
    required List<String> selectedOptionIds,
    required bool isCorrect,
  }) async {
    final participantRef = _participantDoc(eventId, uid);
    final progressRef = participantRef.collection('quizProgress').doc(journal.id);
    final answerRef = progressRef.collection('answers').doc(question.id);
    final scanRef = participantRef.collection('scans').doc(journal.id);
    final eventRef = _firestore.collection('events').doc(eventId);

    final answerSnapshot = await _readLocalFirst(answerRef);
    if (answerSnapshot?.exists ?? false) return;

    final progressSnapshot = await _readLocalFirst(progressRef);
    final earnedPoints = isCorrect ? question.points : 0;
    final previousAnsweredIds = (progressSnapshot?.data()?['answeredQuestionIds'] as List?)?.cast<String>() ?? const [];
    if (previousAnsweredIds.contains(question.id)) return;
    final previousPointsEarned = (progressSnapshot?.data()?['pointsEarned'] as num?)?.toInt() ?? 0;
    final answeredCount = previousAnsweredIds.length + 1;
    final completesQuiz = journal.questionCount > 0 && answeredCount >= journal.questionCount;

    final batch = _firestore.batch()
      ..set(answerRef, {
        'selectedOptionIds': selectedOptionIds,
        'isCorrect': isCorrect,
        'points': earnedPoints,
        'answeredAt': FieldValue.serverTimestamp(),
      })
      ..set(progressRef, {
        'answeredQuestionIds': FieldValue.arrayUnion([question.id]),
        'pointsEarned': FieldValue.increment(earnedPoints),
      }, SetOptions(merge: true));

    if (completesQuiz) {
      final participantSnapshot = await _readLocalFirst(participantRef);
      final eventSnapshot = await _readLocalFirst(eventRef);
      final currentCollected = (participantSnapshot?.data()?['collectedCount'] as num?)?.toInt() ?? 0;
      final journalCount = (eventSnapshot?.data()?['journalCount'] as num?)?.toInt() ?? 0;
      final newCollected = currentCollected + 1;
      final foundAt = Timestamp.now();

      batch
        ..set(scanRef, {'scannedAt': foundAt})
        ..update(participantRef, {
          'collectedCount': FieldValue.increment(1),
          'totalPoints': FieldValue.increment(previousPointsEarned + earnedPoints),
          'lastScanAt': foundAt,
          if (journalCount > 0 && newCollected >= journalCount) 'completedAt': foundAt,
        });
    }
    _commitInBackground(batch);
  }

  /// Whether this participant has finds or quiz answers saved on the device
  /// that haven't reached the server yet.
  Stream<bool> watchHasPendingWrites(String eventId, String uid) {
    final participantRef = _participantDoc(eventId, uid);
    final controller = StreamController<bool>();
    var participantPending = false;
    var quizPending = false;
    void emit() => controller.add(participantPending || quizPending);
    final subscriptions = <StreamSubscription<Object?>>[];
    controller
      ..onListen = () {
        subscriptions
          ..add(
            participantRef.snapshots(includeMetadataChanges: true).listen((doc) {
              participantPending = doc.metadata.hasPendingWrites;
              emit();
            }, onError: controller.addError),
          )
          ..add(
            participantRef.collection('quizProgress').snapshots(includeMetadataChanges: true).listen((snapshot) {
              quizPending = snapshot.metadata.hasPendingWrites;
              emit();
            }, onError: controller.addError),
          );
      }
      ..onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
    return controller.stream.distinct();
  }

  /// Whether anything written on this device is still waiting to sync.
  /// Used to stop a guest signing out (which would drop those writes).
  Future<bool> hasUnsyncedWrites() async {
    try {
      await _firestore.waitForPendingWrites().timeout(const Duration(seconds: 2));
      return false;
    } on TimeoutException {
      return true;
    }
  }

  /// Reads [ref] from the device cache, falling back to the server. Returns
  /// null when neither has it (offline and never cached) — callers treat that
  /// as "not there yet"; the rules still reject a genuine duplicate.
  Future<DocumentSnapshot<Map<String, dynamic>>?> _readLocalFirst(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      return await ref.get(const GetOptions(source: Source.cache));
    } on FirebaseException {
      try {
        return await ref.get().timeout(const Duration(seconds: 3));
      } catch (_) {
        return null;
      }
    }
  }

  /// Offline, a batch's future only completes once the device is back online,
  /// so nothing waits on it. The local cache already shows the write. If the
  /// server later rejects it (e.g. the event closed before it synced) the
  /// cache rolls it back on its own.
  void _commitInBackground(WriteBatch batch) {
    unawaited(
      batch.commit().catchError((Object error) {
        debugPrint('Sync of a gameplay write failed: $error');
      }),
    );
  }
}

class QuizProgress {
  const QuizProgress({required this.answeredQuestionIds, required this.pointsEarned});

  final Set<String> answeredQuestionIds;
  final int pointsEarned;

  factory QuizProgress.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return QuizProgress(
      answeredQuestionIds: ((data['answeredQuestionIds'] as List?)?.cast<String>() ?? const []).toSet(),
      pointsEarned: (data['pointsEarned'] as num?)?.toInt() ?? 0,
    );
  }
}

class QuizAnswerRecord {
  const QuizAnswerRecord({required this.selectedOptionIds, required this.isCorrect, required this.points});

  final Set<String> selectedOptionIds;
  final bool isCorrect;
  final int points;

  factory QuizAnswerRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return QuizAnswerRecord(
      selectedOptionIds: ((data['selectedOptionIds'] as List?)?.cast<String>() ?? const []).toSet(),
      isCorrect: data['isCorrect'] as bool? ?? false,
      points: (data['points'] as num?)?.toInt() ?? 0,
    );
  }
}
