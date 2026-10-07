import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/diamond_marker.dart';
import '../../../routing/route_paths.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../cubit/event_pack_cubit.dart';
import '../cubit/event_pack_state.dart';

/// Shown right after joining an event (and from the Home event card): the
/// progress of getting the event's quests, quizzes and pictures onto the
/// device so the hunt works without signal.
class EventPackScreen extends StatelessWidget {
  const EventPackScreen({super.key});

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: BlocBuilder<EventPackCubit, EventPackState>(
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: DiamondMarker(
                          size: 88,
                          glow: true,
                          child: Icon(_iconFor(state.status), color: AppColors.gold, size: 34),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg32),
                      Text(
                        _titleFor(state.status),
                        style: AppTypography.display(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                      if (state.eventName != null) ...[
                        const SizedBox(height: AppSpacing.xs8),
                        Text(
                          state.eventName!,
                          style: AppTypography.body(color: AppColors.creamDim),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.status == EventPackStatus.idle ? null : state.progress,
                          minHeight: 8,
                          color: AppColors.gold,
                          backgroundColor: AppColors.navyPanel2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md20),
                      _StepRow(
                        label: 'Event details and quests',
                        detail: state.dataReady ? '${state.questCount}' : null,
                        state: _stepState(state, done: state.dataReady),
                      ),
                      _StepRow(
                        label: 'Quiz questions',
                        detail: state.dataReady ? '${state.questionCount}' : null,
                        state: _stepState(state, done: state.dataReady),
                      ),
                      _StepRow(
                        label: 'Pictures',
                        detail: state.imagesTotal == 0 && !state.dataReady
                            ? null
                            : '${state.imagesDone} of ${state.imagesTotal}',
                        state: _stepState(state, done: state.dataReady && state.imagesMissing == 0),
                      ),
                      if (state.bytesDownloaded > 0) ...[
                        const SizedBox(height: AppSpacing.xs8),
                        Text(
                          '${_formatBytes(state.bytesDownloaded)} downloaded',
                          style: AppTypography.body(fontSize: 14, color: AppColors.creamDim),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (_messageFor(state) case final message?) ...[
                        const SizedBox(height: AppSpacing.md20),
                        Text(
                          message,
                          style: AppTypography.body(color: AppColors.creamDim),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (kIsWeb) ...[
                        const SizedBox(height: AppSpacing.sm12),
                        Text(
                          'In a browser, keep this tab open while you play. '
                          'For playing without signal, the phone app works best.',
                          style: AppTypography.body(fontSize: 14, color: AppColors.creamDim),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg32),
                      ..._actionsFor(context, state),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _actionsFor(BuildContext context, EventPackState state) {
    switch (state.status) {
      case EventPackStatus.ready:
        return [AppButton(label: 'Start hunting', onPressed: () => _leave(context))];
      case EventPackStatus.incomplete:
        return [
          AppButton(label: 'Try again', onPressed: () => context.read<EventPackCubit>().prepare()),
          const SizedBox(height: AppSpacing.sm12),
          AppButton(label: 'Play anyway', variant: AppButtonVariant.secondary, onPressed: () => _leave(context)),
        ];
      case EventPackStatus.preparing:
      case EventPackStatus.idle:
        return [
          AppButton(
            label: 'Continue in the background',
            variant: AppButtonVariant.ghost,
            onPressed: () => _leave(context),
          ),
        ];
    }
  }

  static _StepState _stepState(EventPackState state, {required bool done}) {
    if (done) return _StepState.done;
    return state.status == EventPackStatus.incomplete ? _StepState.failed : _StepState.working;
  }

  static IconData _iconFor(EventPackStatus status) => switch (status) {
    EventPackStatus.ready => Icons.check,
    EventPackStatus.incomplete => Icons.cloud_off_outlined,
    _ => Icons.download_outlined,
  };

  static String _titleFor(EventPackStatus status) => switch (status) {
    EventPackStatus.ready => 'Ready to play offline',
    EventPackStatus.incomplete => 'Not everything downloaded',
    _ => 'Getting the hunt ready',
  };

  static String? _messageFor(EventPackState state) {
    switch (state.status) {
      case EventPackStatus.preparing:
      case EventPackStatus.idle:
        return 'Stay on Wi-Fi or mobile data until this finishes, '
            'so the hunt keeps working where there is no signal.';
      case EventPackStatus.ready:
        return null;
      case EventPackStatus.incomplete:
        if (!state.dataReady) {
          return "We couldn't reach the server. Connect to the internet and try again. "
              'You can still play, but quests need signal until this finishes.';
        }
        final missing = state.imagesMissing;
        return '$missing picture${missing == 1 ? '' : 's'} couldn\'t be downloaded. '
            "You can still play. They'll show a placeholder until you're back online.";
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

enum _StepState { working, done, failed }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state, this.detail});

  final String label;
  final String? detail;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs6),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: switch (state) {
              _StepState.done => const Icon(Icons.check_circle, color: AppColors.success, size: 22),
              _StepState.failed => const Icon(Icons.error_outline, color: AppColors.error, size: 22),
              _StepState.working => const Padding(
                padding: EdgeInsets.all(3),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
              ),
            },
          ),
          const SizedBox(width: AppSpacing.sm12),
          Expanded(child: Text(label, style: AppTypography.body())),
          if (detail != null) Text(detail!, style: AppTypography.body(color: AppColors.creamDim)),
        ],
      ),
    );
  }
}
