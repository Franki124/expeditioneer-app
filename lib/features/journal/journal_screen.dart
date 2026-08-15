import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/fading_divider.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/reveal_modal.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../auth/cubit/auth_cubit.dart';
import '../events/cubit/joined_event_cubit.dart';
import '../events/cubit/joined_event_state.dart';
import '../events/data/journal_repository.dart';
import '../events/data/participant_repository.dart';
import '../events/domain/journal.dart';
import '../events/widgets/manual_code_entry.dart';
import '../quiz/presentation/quiz_flow_screen.dart';
import '../quiz/presentation/quiz_review_screen.dart';
import 'widgets/journal_complete_banner.dart';
import 'widgets/quest_card.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthCubit>().state.user?.uid;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Journals', style: AppTypography.display(fontSize: 34), textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(height: AppSpacing.md20),
              Expanded(
                child: BlocBuilder<JoinedEventCubit, JoinedEventState>(
                  builder: (context, state) {
                    final eventId = state.joinedEventId;
                    if (eventId == null || uid == null) {
                      return Center(
                        child: Text(
                          'Join an event from Home to start your journal.',
                          style: AppTypography.body(color: AppColors.creamDim),
                        ),
                      );
                    }
                    return StreamBuilder<List<Journal>>(
                      stream: context.read<JournalRepository>().watchJournals(eventId),
                      builder: (context, journalsSnapshot) {
                        final journals = journalsSnapshot.data ?? const <Journal>[];
                        if (journals.isEmpty) {
                          return Center(
                            child: Text(
                              'No quests found yet.',
                              style: AppTypography.body(color: AppColors.creamDim),
                            ),
                          );
                        }
                        return StreamBuilder<Set<String>>(
                          stream: context
                              .read<ParticipantRepository>()
                              .watchCollectedJournalIds(eventId, uid),
                          builder: (context, collectedSnapshot) {
                            final collected = collectedSnapshot.data ?? const <String>{};
                            return StreamBuilder<Set<String>>(
                              stream: context
                                  .read<ParticipantRepository>()
                                  .watchInProgressQuizIds(eventId, uid),
                              builder: (context, progressSnapshot) {
                                final inProgress = progressSnapshot.data ?? const <String>{};
                                final complete = collected.length >= journals.length;
                                final uncollected =
                                    journals.where((j) => !collected.contains(j.id)).toList();
                                final gestrals =
                                    journals.where((j) => j.type == QuestType.gestral).toList();
                                final journalPages =
                                    journals.where((j) => j.type == QuestType.journal).toList();
                                final quizzes = journals.where((j) => j.type == QuestType.quiz).toList();

                                Widget buildCard(Journal journal) {
                                  final isQuiz = journal.type == QuestType.quiz;
                                  final unlocked = collected.contains(journal.id);
                                  final quizInProgress =
                                      isQuiz && !unlocked && inProgress.contains(journal.id);

                                  VoidCallback onTap;
                                  if (unlocked) {
                                    onTap = isQuiz
                                        ? () => showQuizReview(
                                              context,
                                              eventId: eventId,
                                              uid: uid,
                                              journal: journal,
                                            )
                                        : () => showDialog<void>(
                                              context: context,
                                              builder: (dialogContext) => RevealModal(
                                                journal: journal,
                                                isNewlyCollected: false,
                                                onAddToJournal: () => Navigator.of(dialogContext).pop(),
                                              ),
                                            );
                                  } else if (quizInProgress) {
                                    onTap = () => showQuizFlow(
                                          context,
                                          eventId: eventId,
                                          uid: uid,
                                          journal: journal,
                                        );
                                  } else {
                                    onTap = () => showManualCodeEntry(
                                          context: context,
                                          eventId: eventId,
                                          uid: uid,
                                          uncollected: uncollected,
                                        );
                                  }

                                  return QuestCard(
                                    journal: journal,
                                    unlocked: unlocked,
                                    inProgress: quizInProgress,
                                    onTap: onTap,
                                  );
                                }

                                return FadeSlideIn(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (complete) const JournalCompleteBanner(),
                                      Expanded(
                                        child: ListView(
                                          children: [
                                            if (gestrals.isNotEmpty)
                                              _QuestSection(
                                                title: 'Gestrals',
                                                journals: gestrals,
                                                buildCard: buildCard,
                                              ),
                                            if (journalPages.isNotEmpty)
                                              _QuestSection(
                                                title: 'Journals',
                                                journals: journalPages,
                                                buildCard: buildCard,
                                              ),
                                            if (quizzes.isNotEmpty)
                                              _QuestSection(
                                                title: 'Quizzes',
                                                journals: quizzes,
                                                buildCard: buildCard,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestSection extends StatelessWidget {
  const _QuestSection({required this.title, required this.journals, required this.buildCard});

  final String title;
  final List<Journal> journals;
  final Widget Function(Journal journal) buildCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.label(fontSize: 15)),
        const SizedBox(height: AppSpacing.xs8),
        const FadingDivider(),
        const SizedBox(height: AppSpacing.sm12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: journals.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm12,
            crossAxisSpacing: AppSpacing.sm12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) => buildCard(journals[index]),
        ),
        const SizedBox(height: AppSpacing.md20),
      ],
    );
  }
}
