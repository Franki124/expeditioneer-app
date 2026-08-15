import 'package:cloud_firestore/cloud_firestore.dart';

/// `Journal.type` values. A quiz's `questionCount`/`points`/`difficulty`/
/// `timerSeconds` fields are only meaningful when `type == quest`.
class QuestType {
  QuestType._();

  static const journal = 'journal';
  static const gestral = 'gestral';
  static const quiz = 'quiz';
}

class Journal {
  const Journal({
    required this.id,
    required this.title,
    required this.blurb,
    required this.order,
    required this.artUrl,
    required this.type,
    this.model3dUrl,
    this.manualCode,
    this.points = 10,
    this.difficulty,
    this.timerSeconds,
    this.questionCount = 0,
  });

  final String id;
  final String title;
  final String blurb;
  final int order;
  final String artUrl;
  final String type;
  final String? model3dUrl;
  final int points;

  /// Short human-typeable code printed next to the physical QR sticker, used
  /// as a manual-entry fallback when scanning isn't possible.
  final String? manualCode;

  /// Quiz-only: 'easy' | 'medium' | 'hard'.
  final String? difficulty;

  /// Quiz-only: whole-quiz countdown, null = no limit.
  final int? timerSeconds;

  /// Quiz-only: denormalized count of the `questions` subcollection, so
  /// resumability/completion checks don't need an extra query.
  final int questionCount;

  factory Journal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Journal(
      id: doc.id,
      title: data['title'] as String? ?? '',
      blurb: data['blurb'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      artUrl: data['artUrl'] as String? ?? '',
      type: data['type'] as String? ?? QuestType.journal,
      model3dUrl: data['model3dUrl'] as String?,
      manualCode: data['manualCode'] as String?,
      points: (data['points'] as num?)?.toInt() ?? 10,
      difficulty: data['difficulty'] as String?,
      timerSeconds: (data['timerSeconds'] as num?)?.toInt(),
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Normalizes a code for comparison: trimmed, uppercased, non-alphanumeric
  /// characters stripped, so printed formatting (dashes/spaces) and typing
  /// case don't affect matching.
  static String normalizeCode(String raw) {
    return raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Whether [raw] (an arbitrarily formatted user-typed code) matches this
  /// journal's manual code.
  bool matchesManualCode(String raw) {
    final code = manualCode;
    if (code == null || code.isEmpty) return false;
    return normalizeCode(code) == normalizeCode(raw);
  }
}
