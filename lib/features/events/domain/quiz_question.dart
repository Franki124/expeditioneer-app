import 'package:cloud_firestore/cloud_firestore.dart';

/// `QuizQuestion.answerType` values.
class AnswerType {
  AnswerType._();

  static const single = 'single';
  static const multiple = 'multiple';
}

class QuizOption {
  const QuizOption({required this.id, required this.text, required this.correct});

  final String id;
  final String text;

  /// Exposed to any signed-in reader that can render the quiz at all — an
  /// accepted phase-1 limitation (no Cloud Functions in scope to validate
  /// answers server-side), same posture as the existing `qrToken` note in
  /// firestore.rules. A technical player could read this off the network
  /// response; low stakes for a festival game.
  final bool correct;

  factory QuizOption.fromMap(Map<String, dynamic> map) {
    return QuizOption(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      correct: map['correct'] as bool? ?? false,
    );
  }
}

/// One question in a quiz quest's `questions` subcollection
/// (`events/{eventId}/journals/{journalId}/questions/{questionId}`).
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.imageUrl,
    required this.explanation,
    required this.answerType,
    required this.points,
    required this.order,
    required this.options,
  });

  final String id;
  final String prompt;
  final String imageUrl;
  final String explanation;
  final String answerType;
  final int points;
  final int order;
  final List<QuizOption> options;

  factory QuizQuestion.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return QuizQuestion(
      id: doc.id,
      prompt: data['prompt'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      explanation: data['explanation'] as String? ?? '',
      answerType: data['answerType'] as String? ?? AnswerType.single,
      points: (data['points'] as num?)?.toInt() ?? 10,
      order: (data['order'] as num?)?.toInt() ?? 0,
      options: ((data['options'] as List?) ?? const [])
          .map((raw) => QuizOption.fromMap(Map<String, dynamic>.from(raw as Map)))
          .toList(),
    );
  }
}
