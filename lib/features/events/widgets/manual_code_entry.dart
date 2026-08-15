import 'package:flutter/material.dart';

import '../../../core/utils/upper_case_text_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/motion.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../scan/quest_code_resolver.dart';
import '../domain/journal.dart';

/// Shows a dialog for typing the alphanumeric code printed next to a
/// journal's QR sticker. On a match it resolves the quest exactly like a
/// real camera scan does (see `completeQuestFind`). Shared between the Scan
/// screen and the Journal tab's locked cards so there's one resolve path.
Future<void> showManualCodeEntry({
  required BuildContext context,
  required String eventId,
  required String uid,
  required List<Journal> uncollected,
}) async {
  await showAppDialog<void>(
    context: context,
    builder: (dialogContext) => _ManualCodeDialog(eventId: eventId, uid: uid, uncollected: uncollected),
  );
}

class _ManualCodeDialog extends StatefulWidget {
  const _ManualCodeDialog({required this.eventId, required this.uid, required this.uncollected});

  final String eventId;
  final String uid;
  final List<Journal> uncollected;

  @override
  State<_ManualCodeDialog> createState() => _ManualCodeDialogState();
}

class _ManualCodeDialogState extends State<_ManualCodeDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _controller.text;
    if (raw.trim().isEmpty) {
      setState(() => _error = 'Enter the code printed next to the QR marker.');
      return;
    }
    final journal = findMatchingJournal(raw, widget.uncollected);
    if (journal == null) {
      setState(() => _error = "That code wasn't recognized. Check it and try again.");
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    // Close this dialog right before handing off to the quiz flow or the
    // reveal dialog — two dialogs stacked on top of each other looks wrong.
    final outcome = await completeQuestFind(
      context: context,
      eventId: widget.eventId,
      uid: widget.uid,
      journal: journal,
      beforeNavigate: () => Navigator.of(context).pop(),
    );
    if (outcome == QuestFindOutcome.error && mounted) {
      setState(() {
        _error = "Couldn't save your scan — check your connection and try again.";
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navyPanel2,
      title: Text('Enter code', style: AppTypography.body(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type the alphanumeric code printed next to the QR marker.',
            style: AppTypography.body(color: AppColors.creamDim),
          ),
          const SizedBox(height: AppSpacing.sm12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
            style: AppTypography.body(),
            decoration: InputDecoration(
              hintText: 'e.g. TRV294',
              hintStyle: AppTypography.body(color: AppColors.creamDim),
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _submitting ? null : _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Unlock',
          expand: false,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
