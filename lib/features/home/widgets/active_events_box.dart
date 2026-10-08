import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/connectivity_cubit.dart';
import '../../../core/utils/countdown_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/event_repository.dart';
import '../../events/domain/event.dart';

/// "Happening now" box on the join screen: lists every live event with a
/// one-tap Join so players don't have to type the code. Hidden when nothing
/// is live, and while offline (joining needs the network anyway).
class ActiveEventsBox extends StatefulWidget {
  const ActiveEventsBox({
    super.key,
    required this.onJoin,
    this.joiningEventCode,
  });

  final ValueChanged<Event> onJoin;

  /// Join code currently being validated, so only that row shows a spinner.
  final String? joiningEventCode;

  @override
  State<ActiveEventsBox> createState() => _ActiveEventsBoxState();
}

class _ActiveEventsBoxState extends State<ActiveEventsBox> {
  // Held across rebuilds so the parent's join-status changes don't
  // resubscribe the Firestore query.
  late final Stream<List<Event>> _liveEvents = context.read<EventRepository>().watchLiveEvents();

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityCubit>().state;
    if (!isOnline) return const SizedBox.shrink();

    return StreamBuilder<List<Event>>(
      stream: _liveEvents,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <Event>[];
        if (events.isEmpty) return const SizedBox.shrink();
        final joiningEventCode = widget.joiningEventCode;
        final busy = joiningEventCode != null;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md20),
          child: AppCard(
            highlighted: true,
            padding: const EdgeInsets.all(AppSpacing.sm16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  events.length == 1 ? 'Happening now' : 'Happening now (${events.length})',
                  style: AppTypography.label(fontSize: 12, color: AppColors.gold),
                ),
                for (final (index, event) in events.indexed) ...[
                  SizedBox(height: index == 0 ? AppSpacing.xs8 : AppSpacing.sm12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.name, style: AppTypography.body(fontWeight: FontWeight.w700)),
                            if (event.location.isNotEmpty)
                              Text(event.location, style: AppTypography.body(color: AppColors.creamDim)),
                            Text(
                              formatCountdown(event.endAt),
                              style: AppTypography.body(fontSize: 13, color: AppColors.creamDim),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm12),
                      AppButton(
                        label: 'Join',
                        expand: false,
                        loading: joiningEventCode == event.joinCode,
                        onPressed: busy ? null : () => widget.onJoin(event),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
