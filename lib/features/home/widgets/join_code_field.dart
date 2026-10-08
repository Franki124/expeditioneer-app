import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/upper_case_text_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/motion.dart';
import '../../../routing/route_paths.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../events/cubit/joined_event_cubit.dart';
import '../../events/cubit/joined_event_state.dart';
import 'active_events_box.dart';

class JoinCodeField extends StatefulWidget {
  const JoinCodeField({super.key, required this.displayName});

  final String displayName;

  @override
  State<JoinCodeField> createState() => _JoinCodeFieldState();
}

class _JoinCodeFieldState extends State<JoinCodeField> {
  final _controller = TextEditingController();
  String _lastAttemptedName = '';
  String _lastAttemptedCode = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// [code] defaults to the text field; the "Happening now" box passes the
  /// live event's code directly. Remembered so the name-taken retry re-joins
  /// the same event whichever way it was started.
  void _submit(BuildContext context, {String? code, String? displayName}) {
    final uid = context.read<AuthCubit>().state.user?.uid;
    if (uid == null) return;
    final name = displayName ?? widget.displayName;
    _lastAttemptedName = name;
    _lastAttemptedCode = code ?? _controller.text;
    context.read<JoinedEventCubit>().submitJoinCode(
          _lastAttemptedCode,
          uid: uid,
          displayName: name,
        );
  }

  String? _messageFor(JoinCodeStatus status) {
    switch (status) {
      case JoinCodeStatus.unknownCode:
        return "We couldn't find an event with that code.";
      case JoinCodeStatus.notActivated:
        return 'This event has not started yet.';
      case JoinCodeStatus.closed:
        return 'This event has ended.';
      case JoinCodeStatus.error:
        return "Couldn't join — check your connection and try again.";
      case JoinCodeStatus.validating:
      case JoinCodeStatus.idle:
      case JoinCodeStatus.success:
      case JoinCodeStatus.nameTaken:
        return null;
    }
  }

  Future<void> _showJoinErrorDialog(BuildContext context, String message) async {
    await showAppDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navyPanel2,
        title: Text("Can't join this event", style: AppTypography.body(fontWeight: FontWeight.w700)),
        content: Text(message, style: AppTypography.body(color: AppColors.creamDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (context.mounted) context.read<JoinedEventCubit>().resetJoinCodeStatus();
  }

  Future<void> _showNameTakenDialog(BuildContext context) async {
    final nameController = TextEditingController(text: _lastAttemptedName);
    var retried = false;
    await showAppDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navyPanel2,
        title: Text('That name is taken', style: AppTypography.body(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Someone else in this event is already using that display name. '
              'Pick a different name for this event.',
              style: AppTypography.body(color: AppColors.creamDim),
            ),
            const SizedBox(height: AppSpacing.sm12),
            TextField(
              controller: nameController,
              style: AppTypography.body(),
              decoration: const InputDecoration(
                hintText: 'Display name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Try this name',
            expand: false,
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              retried = true;
              Navigator.of(dialogContext).pop();
              _submit(context, code: _lastAttemptedCode, displayName: newName);
            },
          ),
        ],
      ),
    );
    nameController.dispose();
    if (!retried && context.mounted) context.read<JoinedEventCubit>().resetJoinCodeStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JoinedEventCubit, JoinedEventState>(
      listenWhen: (previous, current) => current.joinCodeStatus != previous.joinCodeStatus,
      listener: (context, state) {
        if (state.joinCodeStatus == JoinCodeStatus.success) {
          _controller.clear();
          context.push(RoutePaths.eventPack);
          return;
        }
        if (state.joinCodeStatus == JoinCodeStatus.nameTaken) {
          _showNameTakenDialog(context);
          return;
        }
        final message = _messageFor(state.joinCodeStatus);
        if (message != null) _showJoinErrorDialog(context, message);
      },
      builder: (context, state) {
        final validating = state.joinCodeStatus == JoinCodeStatus.validating;
        final validatingTyped = validating && _lastAttemptedCode == _controller.text;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActiveEventsBox(
              joiningEventCode: validating && !validatingTyped ? _lastAttemptedCode : null,
              onJoin: (event) => _submit(context, code: event.joinCode),
            ),
            Text('Join a different event', style: AppTypography.body(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter()],
                    style: AppTypography.body(),
                    decoration: InputDecoration(
                      hintText: 'Event code',
                      hintStyle: AppTypography.body(color: AppColors.creamDim),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs8),
                IconButton(
                  onPressed: validating ? null : () => _submit(context),
                  icon: validatingTyped
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward, color: AppColors.gold),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
