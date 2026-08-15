import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/diamond_marker.dart';
import '../../core/widgets/in_app_banner.dart';
import '../../core/widgets/motion.dart';
import '../../routing/route_paths.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/data/auth_repository.dart';
import '../auth/domain/app_user.dart';
import '../events/cubit/joined_event_cubit.dart';
import '../events/cubit/joined_event_state.dart';
import '../events/data/event_repository.dart';
import '../events/data/participant_repository.dart';
import '../events/domain/event.dart';
import '../events/domain/participant.dart';
import 'widgets/join_code_field.dart';
import 'widgets/joined_event_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthCubit>().state.user?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md20),
                child: FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<AppUser?>(
                        stream: context.read<AuthRepository>().watchUserProfile(uid),
                        builder: (context, snapshot) {
                          final name = snapshot.data?.displayName ?? 'Wanderer';
                          return Text('Welcome back, $name', style: AppTypography.display(fontSize: 24));
                        },
                      ),
                      const SizedBox(height: AppSpacing.md20),
                      _JoinedEventSection(uid: uid),
                    ],
                  ),
                ),
              ),
            ),
            const _HowToPlayPrompt(),
          ],
        ),
      ),
    );
  }
}

/// Not joined to anything yet — only place the join-code field is reachable.
/// Once joined, a player must explicitly "Leave current event" (Profile)
/// before this reappears, enforcing one active event at a time. Also watches
/// the joined event's live status to fire an [InAppBanner] the moment it
/// transitions from live to ended, and the joined participant's bonusPoints
/// to fire one when an admin grants (or corrects) points — both while the
/// player has the app open only; no real push notification involved.
class _JoinedEventSection extends StatefulWidget {
  const _JoinedEventSection({required this.uid});

  final String uid;

  @override
  State<_JoinedEventSection> createState() => _JoinedEventSectionState();
}

class _JoinedEventSectionState extends State<_JoinedEventSection> {
  String? _trackedEventId;
  bool? _wasLive;
  int? _lastBonusPoints;

  void _handleEventUpdate(Event? event, String eventId) {
    if (_trackedEventId != eventId) {
      _trackedEventId = eventId;
      _wasLive = event?.isLive;
      _lastBonusPoints = null;
      return;
    }
    final isLive = event?.isLive ?? false;
    if (_wasLive == true && !isLive) {
      final eventName = event?.name ?? 'Your event';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        InAppBanner.show(
          context,
          title: 'Event ended',
          body: '"$eventName" has ended — thanks for playing!',
        );
      });
    }
    _wasLive = isLive;
  }

  void _handleParticipantUpdate(Participant? participant) {
    final bonusPoints = participant?.bonusPoints ?? 0;
    if (_lastBonusPoints == null) {
      _lastBonusPoints = bonusPoints;
      return;
    }
    final delta = bonusPoints - _lastBonusPoints!;
    if (delta != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        InAppBanner.show(
          context,
          title: delta > 0 ? 'Points granted!' : 'Points adjusted',
          body: delta > 0
              ? 'An admin granted you +$delta points.'
              : 'An admin adjusted your points by $delta.',
        );
      });
    }
    _lastBonusPoints = bonusPoints;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JoinedEventCubit, JoinedEventState>(
      builder: (context, state) {
        final joinedEventId = state.joinedEventId;
        if (joinedEventId == null) {
          _trackedEventId = null;
          _wasLive = null;
          _lastBonusPoints = null;
          return StreamBuilder<AppUser?>(
            stream: context.read<AuthRepository>().watchUserProfile(widget.uid),
            builder: (context, snapshot) {
              return JoinCodeField(displayName: snapshot.data?.displayName ?? 'Wanderer');
            },
          );
        }
        return StreamBuilder<Event?>(
          stream: context.read<EventRepository>().watchEvent(joinedEventId),
          builder: (context, eventSnapshot) {
            final event = eventSnapshot.data;
            _handleEventUpdate(event, joinedEventId);
            if (event == null) return const SizedBox.shrink();
            return StreamBuilder<Participant?>(
              stream: context.read<ParticipantRepository>().watchParticipant(joinedEventId, widget.uid),
              builder: (context, participantSnapshot) {
                _handleParticipantUpdate(participantSnapshot.data);
                final collected = participantSnapshot.data?.collectedCount ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      JoinedEventCard(event: event, collectedCount: collected),
                      const SizedBox(height: AppSpacing.sm12),
                      AppButton(
                        label: 'Scan a QR code',
                        onPressed: event.isLive ? () => context.push(RoutePaths.scan) : null,
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
  }
}

class _HowToPlayPrompt extends StatelessWidget {
  const _HowToPlayPrompt();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(RoutePaths.onboarding),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DiamondMarker(
              size: 40,
              child: Text('?', style: AppTypography.display(fontSize: 18, color: AppColors.gold)),
            ),
            const SizedBox(height: AppSpacing.xs8),
            Text(
              'How to play',
              style: AppTypography.label(fontSize: 14, color: AppColors.cream),
            ),
          ],
        ),
      ),
    );
  }
}
