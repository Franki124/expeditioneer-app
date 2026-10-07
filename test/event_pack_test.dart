import 'package:expeditioneer_journal/features/event_pack/cubit/event_pack_state.dart';
import 'package:expeditioneer_journal/features/event_pack/data/event_pack_repository.dart';
import 'package:expeditioneer_journal/features/event_pack/data/pack_file_store.dart';
import 'package:expeditioneer_journal/features/events/domain/event.dart';
import 'package:expeditioneer_journal/features/events/domain/journal.dart';
import 'package:expeditioneer_journal/features/events/domain/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';

Journal _journal(String id, {String type = QuestType.journal, String artUrl = '', int questionCount = 0}) {
  return Journal(
    id: id,
    title: id,
    blurb: '',
    order: 0,
    artUrl: artUrl,
    type: type,
    model3dUrl: type == QuestType.gestral ? 'https://example.com/$id.glb' : null,
    questionCount: questionCount,
  );
}

QuizQuestion _question(String id, {String imageUrl = ''}) {
  return QuizQuestion(
    id: id,
    prompt: id,
    imageUrl: imageUrl,
    explanation: '',
    answerType: AnswerType.single,
    points: 10,
    order: 0,
    options: const [],
  );
}

final _event = Event(
  id: 'e1',
  name: 'Hunt',
  location: '',
  joinCode: 'ABC',
  startAt: DateTime(2026),
  endAt: DateTime(2027),
  status: 'live',
  journalCount: 3,
);

void main() {
  group('EventPackContent', () {
    test('collects quest art and quiz images, skipping blanks, duplicates and 3D models', () {
      final content = EventPackContent(
        event: _event,
        journals: [
          _journal('j1', artUrl: 'https://img/a.jpg'),
          _journal('g1', type: QuestType.gestral, artUrl: 'https://img/a.jpg'),
          _journal('q1', type: QuestType.quiz, questionCount: 2),
        ],
        questionsByQuiz: {
          'q1': [_question('x', imageUrl: 'https://img/b.jpg'), _question('y')],
        },
      );

      expect(content.imageUrls, {'https://img/a.jpg', 'https://img/b.jpg'});
      expect(content.questionCount, 2);
      expect(content.hasAllQuestions, isTrue);
    });

    test('reports a quiz with fewer cached questions than expected as incomplete', () {
      final content = EventPackContent(
        event: _event,
        journals: [_journal('q1', type: QuestType.quiz, questionCount: 3)],
        questionsByQuiz: {
          'q1': [_question('x')],
        },
      );

      expect(content.hasAllQuestions, isFalse);
    });
  });

  group('EventPackState', () {
    test('progress counts the data step and every image', () {
      const state = EventPackState(dataReady: true, imagesTotal: 3, imagesDone: 1);
      expect(state.progress, 0.5);
      expect(state.imagesMissing, 2);
    });

    test('progress is zero before anything is fetched', () {
      expect(const EventPackState().progress, 0);
    });
  });

  test('packImageUrl caps the width of Cloudinary images and leaves other URLs alone', () {
    expect(
      packImageUrl('https://res.cloudinary.com/demo/image/upload/v1/a.jpg'),
      'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,c_limit,w_1200/v1/a.jpg',
    );
    expect(packImageUrl('https://example.com/a.jpg'), 'https://example.com/a.jpg');
  });
}
