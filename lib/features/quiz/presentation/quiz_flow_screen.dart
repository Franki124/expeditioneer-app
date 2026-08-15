import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/cloudinary_image.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/diamond_marker.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/journal_repository.dart';
import '../../events/data/participant_repository.dart';
import '../../events/domain/journal.dart';
import '../../events/domain/quiz_question.dart';

/// Entry point: finding a quiz (scan/manual code) navigates straight here
/// instead of showing `RevealModal` — the quiz doesn't "collect" until every
/// question is answered (see `ParticipantRepository.submitQuizAnswer`).
/// Resolves `true` if the quiz was finished this visit (all questions
/// answered, including via timeout), `false` if the player backed out
/// early — callers that auto-navigate onward (e.g. leaving the Scan screen)
/// should only do so on `true`.
Future<bool> showQuizFlow(
  BuildContext context, {
  required String eventId,
  required String uid,
  required Journal journal,
}) async {
  final finished = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (routeContext) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: context.read<JournalRepository>()),
          RepositoryProvider.value(value: context.read<ParticipantRepository>()),
        ],
        child: _QuizFlowScreen(eventId: eventId, uid: uid, journal: journal),
      ),
    ),
  );
  return finished ?? false;
}

class _QuizFlowScreen extends StatefulWidget {
  const _QuizFlowScreen({required this.eventId, required this.uid, required this.journal});

  final String eventId;
  final String uid;
  final Journal journal;

  @override
  State<_QuizFlowScreen> createState() => _QuizFlowScreenState();
}

class _QuizFlowScreenState extends State<_QuizFlowScreen> {
  final _pageController = PageController();
  List<QuizQuestion>? _questions;
  final Set<String> _answeredIds = {};
  int _pointsEarned = 0;
  int _currentPage = 0;
  Timer? _timer;
  int? _secondsRemaining;
  bool _finished = false;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = context.read<JournalRepository>();
    final participantRepository = context.read<ParticipantRepository>();
    final questions = await repository.watchQuestions(widget.eventId, widget.journal.id).first;
    final progress =
        await participantRepository.watchQuizProgress(widget.eventId, widget.uid, widget.journal.id).first;
    if (!mounted) return;
    setState(() {
      _questions = questions;
      if (progress != null) {
        _answeredIds.addAll(progress.answeredQuestionIds);
        _pointsEarned = progress.pointsEarned;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  int get _firstUnansweredIndex {
    final questions = _questions!;
    for (var i = 0; i < questions.length; i++) {
      if (!_answeredIds.contains(questions[i].id)) return i;
    }
    return questions.length; // fully answered
  }

  void _start() {
    final timerSeconds = widget.journal.timerSeconds;
    if (timerSeconds != null && _timer == null) {
      final alreadyElapsed = 0; // timer restarts fresh each app session; acceptable for phase 1
      _secondsRemaining = timerSeconds - alreadyElapsed;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
    final target = _firstUnansweredIndex;
    if (target >= _questions!.length) {
      _goToCompletion();
      return;
    }
    _pageController.animateToPage(
      target + 1, // +1: page 0 is the cover
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _secondsRemaining = (_secondsRemaining ?? 0) - 1);
    if ((_secondsRemaining ?? 0) <= 0) {
      _timer?.cancel();
      _autoSubmitRemaining();
    }
  }

  Future<void> _autoSubmitRemaining() async {
    if (!mounted) return;
    setState(() => _timedOut = true);
    final questions = _questions!;
    for (final question in questions) {
      if (_answeredIds.contains(question.id)) continue;
      await _submitAnswer(question, const [], false);
    }
    _goToCompletion();
  }

  Future<void> _submitAnswer(QuizQuestion question, List<String> selectedOptionIds, bool isCorrect) async {
    await context.read<ParticipantRepository>().submitQuizAnswer(
          eventId: widget.eventId,
          uid: widget.uid,
          journalId: widget.journal.id,
          questionDocId: question.id,
          selectedOptionIds: selectedOptionIds,
          isCorrect: isCorrect,
          points: question.points,
        );
    if (!mounted) return;
    setState(() {
      _answeredIds.add(question.id);
      if (isCorrect) _pointsEarned += question.points;
    });
  }

  Future<void> _handleAnswered(QuizQuestion question, List<String> selectedOptionIds, bool isCorrect) async {
    await _submitAnswer(question, selectedOptionIds, isCorrect);
  }

  void _next() {
    final questions = _questions!;
    if (_currentPage - 1 + 1 >= questions.length) {
      _goToCompletion();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _goToCompletion() {
    _timer?.cancel();
    setState(() => _finished = true);
    _pageController.animateToPage(
      _questions!.length + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: Text(widget.journal.title),
        actions: [
          if (_secondsRemaining != null && !_finished)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md20),
              child: Center(
                child: Text(
                  _formatSeconds(_secondsRemaining!),
                  style: AppTypography.body(
                    fontWeight: FontWeight.w800,
                    color: _secondsRemaining! < 30 ? AppColors.error : AppColors.gold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: questions == null
            ? const Center(child: CircularProgressIndicator())
            : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _CoverPage(
                    journal: widget.journal,
                    questionCount: questions.length,
                    resuming: _answeredIds.isNotEmpty,
                    onStart: _start,
                  ),
                  for (var i = 0; i < questions.length; i++)
                    _QuestionPage(
                      question: questions[i],
                      index: i,
                      total: questions.length,
                      isLast: i == questions.length - 1,
                      alreadyAnswered: _answeredIds.contains(questions[i].id),
                      onAnswered: (selected, correct) => _handleAnswered(questions[i], selected, correct),
                      onNext: _next,
                    ),
                  _CompletionPage(
                    pointsEarned: _pointsEarned,
                    totalPoints: questions.fold<int>(0, (total, q) => total + q.points),
                    timedOut: _timedOut,
                    onDone: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final minutes = s ~/ 60;
    final secs = s % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

class _CoverPage extends StatelessWidget {
  const _CoverPage({
    required this.journal,
    required this.questionCount,
    required this.resuming,
    required this.onStart,
  });

  final Journal journal;
  final int questionCount;
  final bool resuming;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const DiamondMarker(
            size: 88,
            glow: true,
            child: Icon(Icons.quiz_outlined, color: AppColors.gold, size: 34),
          ),
          const SizedBox(height: AppSpacing.lg32),
          if (journal.difficulty != null) ...[
            _DifficultyPill(difficulty: journal.difficulty!),
            const SizedBox(height: AppSpacing.sm12),
          ],
          Text(journal.title, style: AppTypography.display(fontSize: 26), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm12),
          Text(
            journal.blurb,
            style: AppTypography.body(color: AppColors.creamDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md20),
          Text(
            '$questionCount question${questionCount == 1 ? '' : 's'}'
            '${journal.timerSeconds != null ? ' · ${(journal.timerSeconds! / 60).ceil()} min limit' : ''}',
            style: AppTypography.body(fontSize: 15, color: AppColors.creamDim),
          ),
          const SizedBox(height: AppSpacing.lg32),
          AppButton(label: resuming ? 'Resume quiz' : 'Start quiz', onPressed: onStart),
        ],
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  const _DifficultyPill({required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      'hard' => AppColors.error,
      'medium' => AppColors.gold,
      _ => AppColors.success,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm12, vertical: AppSpacing.xs4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadii.pillShape,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: AppTypography.label(fontSize: 13, color: color),
      ),
    );
  }
}

class _QuestionPage extends StatefulWidget {
  const _QuestionPage({
    required this.question,
    required this.index,
    required this.total,
    required this.isLast,
    required this.alreadyAnswered,
    required this.onAnswered,
    required this.onNext,
  });

  final QuizQuestion question;
  final int index;
  final int total;
  final bool isLast;
  final bool alreadyAnswered;
  final Future<void> Function(List<String> selectedOptionIds, bool isCorrect) onAnswered;
  final VoidCallback onNext;

  @override
  State<_QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<_QuestionPage> {
  final Set<String> _selected = {};
  bool _locked = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Resuming past an already-answered question — show it locked with no
    // selection detail (the per-answer record isn't re-fetched here, just
    // the fact that it's done), matching "no going back to change it."
    _locked = widget.alreadyAnswered;
  }

  Set<String> get _correctIds =>
      widget.question.options.where((o) => o.correct).map((o) => o.id).toSet();

  bool get _isCorrect => _selected.length == _correctIds.length && _selected.containsAll(_correctIds);

  Future<void> _lockIn() async {
    setState(() => _submitting = true);
    await widget.onAnswered(_selected.toList(), _isCorrect);
    if (mounted) setState(() { _locked = true; _submitting = false; });
  }

  void _tapSingle(String optionId) {
    if (_locked || _submitting) return;
    setState(() => _selected..clear()..add(optionId));
    _lockIn();
  }

  void _toggleMulti(String optionId) {
    if (_locked || _submitting) return;
    setState(() {
      if (_selected.contains(optionId)) {
        _selected.remove(optionId);
      } else {
        _selected.add(optionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final showFeedback = _locked;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${widget.index + 1} of ${widget.total}',
            style: AppTypography.body(fontSize: 14, color: AppColors.creamDim),
          ),
          const SizedBox(height: AppSpacing.sm12),
          if (question.imageUrl.isNotEmpty) ...[
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                cloudinaryDeliveryUrl(question.imageUrl),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: AppColors.navyPanel),
              ),
            ),
            const SizedBox(height: AppSpacing.sm12),
          ],
          Text(question.prompt, style: AppTypography.display(fontSize: 20)),
          const SizedBox(height: AppSpacing.md20),
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm12),
              child: _AnswerButton(
                text: option.text,
                selected: _selected.contains(option.id),
                state: !showFeedback
                    ? _AnswerVisualState.idle
                    : option.correct
                        ? _AnswerVisualState.correct
                        : _selected.contains(option.id)
                            ? _AnswerVisualState.incorrect
                            : _AnswerVisualState.idle,
                multiSelect: question.answerType == AnswerType.multiple,
                onTap: showFeedback || _submitting
                    ? null
                    : () => question.answerType == AnswerType.single
                        ? _tapSingle(option.id)
                        : _toggleMulti(option.id),
              ),
            ),
          if (question.answerType == AnswerType.multiple && !showFeedback) ...[
            const SizedBox(height: AppSpacing.sm12),
            AppButton(
              label: 'Submit answer',
              loading: _submitting,
              onPressed: _selected.isEmpty || _submitting ? null : _lockIn,
            ),
          ],
          if (showFeedback) ...[
            if (question.explanation.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md20),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.sm14),
                child: Text(question.explanation, style: AppTypography.body(color: AppColors.creamDim)),
              ),
            ],
            const SizedBox(height: AppSpacing.md20),
            AppButton(
              label: widget.isLast ? 'Finish' : 'Next question',
              onPressed: widget.onNext,
            ),
          ],
        ],
      ),
    );
  }
}

enum _AnswerVisualState { idle, correct, incorrect }

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.text,
    required this.selected,
    required this.state,
    required this.multiSelect,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final _AnswerVisualState state;
  final bool multiSelect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _AnswerVisualState.correct => AppColors.success,
      _AnswerVisualState.incorrect => AppColors.error,
      _AnswerVisualState.idle => selected ? AppColors.gold : AppColors.creamDim,
    };
    final fillColor = state == _AnswerVisualState.idle
        ? (selected ? AppColors.gold.withValues(alpha: 0.12) : AppColors.navyPanel)
        : color.withValues(alpha: 0.16);
    return ClipRRect(
      borderRadius: AppRadii.card,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm14, vertical: AppSpacing.sm14),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: AppRadii.card,
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                if (multiSelect)
                  Icon(
                    selected ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 18,
                    color: color,
                  ),
                if (multiSelect) const SizedBox(width: AppSpacing.sm12),
                Expanded(child: Text(text, style: AppTypography.body())),
                if (state == _AnswerVisualState.correct)
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                if (state == _AnswerVisualState.incorrect)
                  const Icon(Icons.cancel, color: AppColors.error, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionPage extends StatelessWidget {
  const _CompletionPage({
    required this.pointsEarned,
    required this.totalPoints,
    required this.timedOut,
    required this.onDone,
  });

  final int pointsEarned;
  final int totalPoints;
  final bool timedOut;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const DiamondMarker(
            size: 88,
            filled: true,
            glow: true,
            child: Icon(Icons.emoji_events_outlined, color: AppColors.navyDeep, size: 34),
          ),
          const SizedBox(height: AppSpacing.lg32),
          Text('Quiz complete!', style: AppTypography.display(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm12),
          if (timedOut) ...[
            Text(
              "Time's up — remaining questions were marked unanswered.",
              style: AppTypography.body(color: AppColors.creamDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm12),
          ],
          Text(
            '$pointsEarned / $totalPoints points',
            style: AppTypography.display(fontSize: 20, color: AppColors.gold),
          ),
          const SizedBox(height: AppSpacing.lg32),
          AppButton(label: 'Back to journal', onPressed: onDone),
        ],
      ),
    );
  }
}
