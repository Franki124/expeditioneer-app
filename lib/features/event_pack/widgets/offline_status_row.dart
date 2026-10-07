import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/route_paths.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/data/participant_repository.dart';
import '../cubit/event_pack_cubit.dart';
import '../cubit/event_pack_state.dart';

/// One line under the Home event card: whether the event is downloaded for
/// offline play, and whether any finds are still waiting to sync. Tapping it
/// opens the download screen.
class OfflineStatusRow extends StatefulWidget {
  const OfflineStatusRow({super.key, required this.eventId, required this.uid});

  final String eventId;
  final String uid;

  @override
  State<OfflineStatusRow> createState() => _OfflineStatusRowState();
}

class _OfflineStatusRowState extends State<OfflineStatusRow> {
  late Stream<bool> _pendingWrites;

  @override
  void initState() {
    super.initState();
    _pendingWrites = _watch();
  }

  @override
  void didUpdateWidget(OfflineStatusRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId || oldWidget.uid != widget.uid) _pendingWrites = _watch();
  }

  Stream<bool> _watch() => context.read<ParticipantRepository>().watchHasPendingWrites(widget.eventId, widget.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _pendingWrites,
      builder: (context, pendingSnapshot) {
        final pending = pendingSnapshot.data ?? false;
        return BlocBuilder<EventPackCubit, EventPackState>(
          builder: (context, state) {
            final (icon, color, text) = switch (state.status) {
              EventPackStatus.ready => (Icons.offline_pin_outlined, AppColors.success, 'Ready to play offline'),
              EventPackStatus.incomplete => (
                Icons.cloud_off_outlined,
                AppColors.error,
                state.dataReady
                    ? '${state.imagesMissing} picture${state.imagesMissing == 1 ? '' : 's'} not downloaded'
                    : 'Not downloaded for offline play',
              ),
              _ => (
                Icons.downloading_outlined,
                AppColors.creamDim,
                state.imagesTotal > 0
                    ? 'Downloading for offline play (${state.imagesDone} of ${state.imagesTotal})'
                    : 'Downloading for offline play',
              ),
            };
            return InkWell(
              onTap: () => context.push(RoutePaths.eventPack),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Line(icon: icon, color: color, text: text),
                    if (pending) ...[
                      const SizedBox(height: AppSpacing.xs4),
                      const _Line(icon: Icons.sync, color: AppColors.gold, text: 'Finds waiting to sync'),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.xs8),
        Expanded(
          child: Text(text, style: AppTypography.body(fontSize: 14, color: color)),
        ),
      ],
    );
  }
}
