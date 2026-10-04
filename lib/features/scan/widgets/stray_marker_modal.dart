import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/corner_frame.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// Lore lines for a QR code that isn't part of this event. One is picked at
/// random each time so repeat misfires don't read like the same error.
const _unknownLines = [
  "This sigil belongs to no expedition we know. Perhaps a decoy left by a rival cartographer.",
  "The ink is foreign and the runes won't speak. Whatever this code guards, it isn't on our map.",
  "Your compass spins and settles nowhere. This mark was never charted by the expedition.",
  "The journal stays silent. Only markers sealed with the expedition's gold frame will answer you.",
];

/// The dialog shown when the camera reads a QR code that doesn't unlock a new
/// quest: either a code from outside the game, or a quest the player has
/// already collected ([alreadyFoundTitle] set).
class StrayMarkerModal extends StatefulWidget {
  const StrayMarkerModal({super.key, required this.onClose, this.alreadyFoundTitle});

  final VoidCallback onClose;

  /// Title of the already-collected quest this code belongs to, or null when
  /// the code matches nothing at this event.
  final String? alreadyFoundTitle;

  @override
  State<StrayMarkerModal> createState() => _StrayMarkerModalState();
}

class _StrayMarkerModalState extends State<StrayMarkerModal> {
  late final String _unknownLine = _unknownLines[math.Random().nextInt(_unknownLines.length)];

  @override
  Widget build(BuildContext context) {
    final alreadyFound = widget.alreadyFoundTitle;
    final title = alreadyFound == null ? 'An uncharted mark' : 'Already charted';
    final body = alreadyFound == null
        ? _unknownLine
        : 'You already inked "$alreadyFound" into your journal. Its secrets are yours, so seek the next marker.';
    final hint = alreadyFound == null ? 'Seek the markers placed for this event.' : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.dialogMaxWidth),
        child: CornerFrame(
          padding: const EdgeInsets.all(AppSpacing.md20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                alreadyFound == null ? Icons.explore_off_outlined : Icons.auto_stories_outlined,
                color: alreadyFound == null ? AppColors.danger : AppColors.gold,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.sm12),
              Text(title, style: AppTypography.display(fontSize: 20), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs8),
              Text(
                body,
                style: AppTypography.body(color: AppColors.creamDim),
                textAlign: TextAlign.center,
              ),
              if (hint != null) ...[
                const SizedBox(height: AppSpacing.xs8),
                Text(hint, style: AppTypography.label(fontSize: 13), textAlign: TextAlign.center),
              ],
              const SizedBox(height: AppSpacing.md20),
              AppButton(label: alreadyFound == null ? 'Keep searching' : 'Onward', onPressed: widget.onClose),
            ],
          ),
        ),
      ),
    );
  }
}
