import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/events/domain/journal.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../utils/cloudinary_image.dart';
import 'app_button.dart';
import 'corner_frame.dart';

/// The 3D flip-in reveal card (rotateY 90deg -> 0deg) shown after a
/// successful scan.
class RevealModal extends StatefulWidget {
  const RevealModal({
    super.key,
    required this.journal,
    required this.onAddToJournal,
    this.isNewlyCollected = true,
  });

  final Journal journal;
  final VoidCallback onAddToJournal;

  /// Whether this reveal is for a quest just collected (shows "Add to
  /// journal") vs. reopening an already-collected quest from the Journal tab
  /// (shows "Close").
  final bool isNewlyCollected;

  @override
  State<RevealModal> createState() => _RevealModalState();
}

class _RevealModalState extends State<RevealModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tag = switch (widget.journal.type) {
      QuestType.gestral => 'Gestral',
      QuestType.quiz => 'Quiz',
      _ => 'Journal',
    };
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = (1 - _controller.value) * math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Opacity(opacity: _controller.value.clamp(0, 1), child: child),
          );
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            maxWidth: AppBreakpoints.dialogMaxWidth,
          ),
          child: CornerFrame(
            padding: const EdgeInsets.all(AppSpacing.md20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Aspect-ratio'd instead of a fixed pixel height, so the
                  // art scales with whatever width the dialog actually
                  // gets (native-mobile full width vs. the web letterbox's
                  // dialogMaxWidth cap) rather than looking over/under-sized
                  // on screens the fixed height wasn't tuned for.
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: widget.journal.artUrl.isEmpty
                        ? _ArtPlaceholder(tag: tag)
                        : ColoredBox(
                            color: AppColors.navyPanel,
                            child: Image.network(
                              cloudinaryDeliveryUrl(widget.journal.artUrl),
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => _ArtPlaceholder(tag: tag),
                              loadingBuilder: (context, child, progress) =>
                                  progress == null ? child : _ArtPlaceholder(tag: tag),
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.sm12),
                  Text(tag, style: AppTypography.label(fontSize: 13)),
                  const SizedBox(height: AppSpacing.xs4),
                  Text(widget.journal.title, style: AppTypography.display(fontSize: 20), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xs8),
                  Text(
                    widget.journal.blurb,
                    style: AppTypography.body(color: AppColors.creamDim),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md20),
                  AppButton(
                    label: widget.isNewlyCollected ? 'Add to journal' : 'Close',
                    onPressed: widget.onAddToJournal,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtPlaceholder extends StatelessWidget {
  const _ArtPlaceholder({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.navyPanel,
      child: Center(
        child: Text(tag, style: AppTypography.body(color: AppColors.creamDim)),
      ),
    );
  }
}
