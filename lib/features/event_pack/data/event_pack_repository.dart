import 'package:cloud_firestore/cloud_firestore.dart';

import '../../events/domain/event.dart';
import '../../events/domain/journal.dart';
import '../../events/domain/quiz_question.dart';

/// Everything about one event the hunt needs, read in one go.
class EventPackContent {
  const EventPackContent({required this.event, required this.journals, required this.questionsByQuiz});

  final Event event;
  final List<Journal> journals;
  final Map<String, List<QuizQuestion>> questionsByQuiz;

  Iterable<Journal> get quizzes => journals.where((j) => j.type == QuestType.quiz);

  int get questionCount => questionsByQuiz.values.fold(0, (total, list) => total + list.length);

  /// Whether every quiz has all the questions its quest doc says it has.
  bool get hasAllQuestions => quizzes.every((quiz) => (questionsByQuiz[quiz.id]?.length ?? 0) >= quiz.questionCount);

  /// Every image the hunt can show: quest art and quiz question images.
  /// Gestral 3D models are left out on purpose (the feature may be removed).
  Set<String> get imageUrls => {
    for (final journal in journals)
      if (journal.artUrl.isNotEmpty) journal.artUrl,
    for (final questions in questionsByQuiz.values)
      for (final question in questions)
        if (question.imageUrl.isNotEmpty) question.imageUrl,
  };
}

/// Reads an event's quests and quiz questions. Reading from the server also
/// stores them in Firestore's on-device cache, which is what the game screens
/// read from when there's no signal; reading from the cache checks they're
/// actually there.
class EventPackRepository {
  EventPackRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Returns null when the event doc isn't available from [source].
  Future<EventPackContent?> load(String eventId, {required Source source}) async {
    final options = GetOptions(source: source);
    final eventRef = _firestore.collection('events').doc(eventId);
    final eventDoc = await eventRef.get(options);
    if (!eventDoc.exists) return null;

    // Same query as JournalRepository.watchJournals, so the cached result is
    // the one the Journal and Scan screens get offline.
    final journalsSnapshot = await eventRef.collection('journals').orderBy('order').get(options);
    final journals = journalsSnapshot.docs.map(Journal.fromDoc).toList();

    final questionsByQuiz = <String, List<QuizQuestion>>{};
    await Future.wait([
      for (final quiz in journals.where((j) => j.type == QuestType.quiz))
        eventRef
            .collection('journals')
            .doc(quiz.id)
            .collection('questions')
            .orderBy('order')
            .get(options)
            .then((snapshot) => questionsByQuiz[quiz.id] = snapshot.docs.map(QuizQuestion.fromDoc).toList()),
    ]);

    return EventPackContent(event: Event.fromDoc(eventDoc), journals: journals, questionsByQuiz: questionsByQuiz);
  }
}
