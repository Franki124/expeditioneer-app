import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/cloudinary_image.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/motion.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/journal_repository.dart';
import '../../events/data/participant_repository.dart';
import '../../events/domain/journal.dart';
import '../../events/domain/quiz_question.dart';

/// Read-only look back at a finished quiz — no retake, but the content stays
/// inspectable: each question, what the player picked, what was actually
/// correct, and the explanation.
Future<void> showQuizReview(
  BuildContext context, {
  required String eventId,
  required String uid,
  required Journal journal,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (routeContext) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: context.read<JournalRepository>()),
          RepositoryProvider.value(value: context.read<ParticipantRepository>()),
        ],
        child: _QuizReviewScreen(eventId: eventId, uid: uid, journal: journal),
      ),
    ),
  );
}

class _QuizReviewScreen extends StatefulWidget {
  const _QuizReviewScreen({required this.eventId, required this.uid, required this.journal});

  final String eventId;
  final String uid;
  final Journal journal;

  @override
  State<_QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends State<_QuizReviewScreen> {
  List<QuizQuestion>? _questions;
  Map<String, QuizAnswerRecord>? _answers;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final journalRepository = context.read<JournalRepository>();
    final participantRepository = context.read<ParticipantRepository>();
    final questions = await journalRepository.watchQuestions(widget.eventId, widget.journal.id).first;
    final answers = await participantRepository.getQuizAnswers(widget.eventId, widget.uid, widget.journal.id);
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _answers = answers;
    });
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    final answers = _answers;
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(backgroundColor: AppColors.navy, title: Text(widget.journal.title)),
      body: SafeArea(
        child: questions == null || answers == null
            ? const Center(child: CircularProgressIndicator())
            : FadeSlideIn(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md20),
                  children: [
                    for (final question in questions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md20),
                        child: _ReviewQuestionCard(question: question, answer: answers[question.id]),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ReviewQuestionCard extends StatelessWidget {
  const _ReviewQuestionCard({required this.question, required this.answer});

  final QuizQuestion question;
  final QuizAnswerRecord? answer;

  @override
  Widget build(BuildContext context) {
    final selected = answer?.selectedOptionIds ?? const <String>{};
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.imageUrl.isNotEmpty) ...[
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: AppColors.navyPanel2,
                child: Image.network(
                  cloudinaryDeliveryUrl(question.imageUrl),
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(color: AppColors.navyPanel2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm12),
          ],
          Text(question.prompt, style: AppTypography.display(fontSize: 18)),
          const SizedBox(height: AppSpacing.sm12),
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs8),
              child: Row(
                children: [
                  Icon(
                    option.correct
                        ? Icons.check_circle
                        : (selected.contains(option.id) ? Icons.cancel : Icons.circle_outlined),
                    size: 16,
                    color: option.correct
                        ? AppColors.success
                        : (selected.contains(option.id) ? AppColors.error : AppColors.creamDim),
                  ),
                  const SizedBox(width: AppSpacing.xs8),
                  Expanded(
                    child: Text(
                      option.text,
                      style: AppTypography.body(
                        color: option.correct || selected.contains(option.id)
                            ? AppColors.cream
                            : AppColors.creamDim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs8),
            Text(question.explanation, style: AppTypography.body(fontSize: 15, color: AppColors.creamDim)),
          ],
          const SizedBox(height: AppSpacing.xs8),
          Text(
            '${answer?.points ?? 0} / ${question.points} pts',
            style: AppTypography.body(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}
