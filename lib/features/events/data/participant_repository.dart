import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Records a scan atomically: no-op if already collected, otherwise creates
  /// the immutable scan doc and increments the participant's collectedCount
  /// (+ completedAt once every journal in the event is collected).
  Future<void> recordScan({
    required String eventId,
    required String uid,
    required String journalId,
  }) async {
    final participantRef = _participantDoc(eventId, uid);
    final scanRef = participantRef.collection('scans').doc(journalId);
    final eventRef = _firestore.collection('events').doc(eventId);
    final journalRef = eventRef.collection('journals').doc(journalId);

    await _firestore.runTransaction((transaction) async {
      final scanSnapshot = await transaction.get(scanRef);
      if (scanSnapshot.exists) return;

      final journalSnapshot = await transaction.get(journalRef);
      final participantSnapshot = await transaction.get(participantRef);
      final eventSnapshot = await transaction.get(eventRef);
      final currentCollected =
          (participantSnapshot.data()?['collectedCount'] as num?)?.toInt() ?? 0;
      final journalCount = (eventSnapshot.data()?['journalCount'] as num?)?.toInt() ?? 0;
      final journalPoints = (journalSnapshot.data()?['points'] as num?)?.toInt() ?? 10;
      final newCollected = currentCollected + 1;

      transaction.set(scanRef, {'scannedAt': FieldValue.serverTimestamp()});
      transaction.update(participantRef, {
        'collectedCount': newCollected,
        'totalPoints': FieldValue.increment(journalPoints),
        'lastScanAt': FieldValue.serverTimestamp(),
        if (journalCount > 0 && newCollected >= journalCount)
          'completedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(journalRef, {'scanCount': FieldValue.increment(1)});
    });
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

  /// Records one answered quiz question: no-op if this question was already
  /// answered (immutable `answers/{questionId}` doc, same create-only-no-op
  /// shape as `recordScan`'s `scans/{journalId}`), otherwise writes the
  /// answer, bumps the running `quizProgress` aggregate, and — if this was
  /// the quiz's last unanswered question — also performs exactly the same
  /// participant-level bookkeeping `recordScan` does (creates `scans/
  /// {journalId}`, bumps `collectedCount`/`totalPoints`/`completedAt`), so
  /// every existing "is this collected" check keeps working for quizzes too.
  Future<void> submitQuizAnswer({
    required String eventId,
    required String uid,
    required String journalId,
    required List<String> selectedOptionIds,
    required bool isCorrect,
    required String questionDocId,
    required int points,
  }) async {
    final participantRef = _participantDoc(eventId, uid);
    final progressRef = participantRef.collection('quizProgress').doc(journalId);
    final answerRef = progressRef.collection('answers').doc(questionDocId);
    final scanRef = participantRef.collection('scans').doc(journalId);
    final eventRef = _firestore.collection('events').doc(eventId);
    final journalRef = eventRef.collection('journals').doc(journalId);

    await _firestore.runTransaction((transaction) async {
      final answerSnapshot = await transaction.get(answerRef);
      if (answerSnapshot.exists) return;

      // All reads up front — Firestore transactions require every get()
      // before any set()/update(), so participant/event are read
      // unconditionally even though they're only used if this answer
      // completes the quiz.
      final progressSnapshot = await transaction.get(progressRef);
      final journalSnapshot = await transaction.get(journalRef);
      final participantSnapshot = await transaction.get(participantRef);
      final eventSnapshot = await transaction.get(eventRef);

      final questionCount = (journalSnapshot.data()?['questionCount'] as num?)?.toInt() ?? 0;
      final earnedPoints = isCorrect ? points : 0;

      final previousAnsweredIds =
          (progressSnapshot.data()?['answeredQuestionIds'] as List?)?.cast<String>() ?? const [];
      final previousPointsEarned = (progressSnapshot.data()?['pointsEarned'] as num?)?.toInt() ?? 0;
      final newAnsweredIds = [...previousAnsweredIds, questionDocId];
      final newPointsEarned = previousPointsEarned + earnedPoints;

      transaction.set(answerRef, {
        'selectedOptionIds': selectedOptionIds,
        'isCorrect': isCorrect,
        'points': earnedPoints,
        'answeredAt': FieldValue.serverTimestamp(),
      });
      transaction.set(progressRef, {
        'answeredQuestionIds': newAnsweredIds,
        'pointsEarned': newPointsEarned,
      });

      if (questionCount > 0 && newAnsweredIds.length >= questionCount) {
        final currentCollected = (participantSnapshot.data()?['collectedCount'] as num?)?.toInt() ?? 0;
        final journalCount = (eventSnapshot.data()?['journalCount'] as num?)?.toInt() ?? 0;
        final newCollected = currentCollected + 1;

        transaction.set(scanRef, {'scannedAt': FieldValue.serverTimestamp()});
        transaction.update(participantRef, {
          'collectedCount': newCollected,
          'totalPoints': FieldValue.increment(newPointsEarned),
          'lastScanAt': FieldValue.serverTimestamp(),
          if (journalCount > 0 && newCollected >= journalCount)
            'completedAt': FieldValue.serverTimestamp(),
        });
      }
    });
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
