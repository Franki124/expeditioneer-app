import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/journal.dart';
import '../domain/quiz_question.dart';

class JournalRepository {
  JournalRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Journal>> watchJournals(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('journals')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Journal.fromDoc).toList());
  }

  Stream<List<QuizQuestion>> watchQuestions(String eventId, String journalId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('journals')
        .doc(journalId)
        .collection('questions')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(QuizQuestion.fromDoc).toList());
  }
}
