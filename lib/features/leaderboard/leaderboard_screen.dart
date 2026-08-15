import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/motion.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../auth/cubit/auth_cubit.dart';
import '../events/cubit/joined_event_cubit.dart';
import '../events/cubit/joined_event_state.dart';
import '../events/data/event_repository.dart';
import '../events/data/participant_repository.dart';
import '../events/domain/event.dart';
import '../events/domain/participant.dart';
import 'widgets/live_pulse_indicator.dart';
import 'widgets/rank_row.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Leaderboard', style: AppTypography.display()),
                  const LivePulseIndicator(),
                ],
              ),
              const SizedBox(height: AppSpacing.md20),
              Expanded(
                child: BlocBuilder<JoinedEventCubit, JoinedEventState>(
                  builder: (context, state) {
                    final eventId = state.joinedEventId;
                    if (eventId == null) {
                      return Center(
                        child: Text(
                          'Join an event from Home to see the leaderboard.',
                          style: AppTypography.body(color: AppColors.creamDim),
                        ),
                      );
                    }
                    return StreamBuilder<Event?>(
                      stream: context.read<EventRepository>().watchEvent(eventId),
                      builder: (context, eventSnapshot) {
                        final event = eventSnapshot.data;
                        if (event != null && !event.isLive) {
                          return Center(
                            child: Text(
                              'This event has ended.',
                              style: AppTypography.body(color: AppColors.creamDim),
                            ),
                          );
                        }
                        return StreamBuilder<List<Participant>>(
                          stream: context.read<ParticipantRepository>().watchLeaderboard(eventId),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Could not load the leaderboard: ${snapshot.error}',
                                  style: AppTypography.body(color: AppColors.error),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            final rows = snapshot.data ?? const <Participant>[];
                            if (rows.isEmpty) {
                              return Center(
                                child: Text(
                                  'No one has joined yet — be the first!',
                                  style: AppTypography.body(color: AppColors.creamDim),
                                ),
                              );
                            }
                            return FadeSlideIn(
                              child: ListView.builder(
                                itemCount: rows.length,
                                itemBuilder: (context, index) => RankRow(
                                  rank: index + 1,
                                  participant: rows[index],
                                  highlight: rows[index].uid == uid,
                                ),
                              ),
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
