import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// A local, Android-style system notification banner sliding down from the
/// top (`pushSlideDown`) — no real FCM involved, used for in-app-only
/// notices (e.g. "your event just ended") while the player has the app open.
class InAppBanner {
  static void show(BuildContext context, {required String title, required String body}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Banner(
        title: title,
        body: body,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _Banner extends StatefulWidget {
  const _Banner({required this.title, required this.body, required this.onDismiss});

  final String title;
  final String body;
  final VoidCallback onDismiss;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _offset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2500), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offset,
          child: GestureDetector(
            onTap: _dismiss,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm12),
              child: Material(
                color: AppColors.navyPanel2,
                borderRadius: AppRadii.card,
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
                        alignment: Alignment.center,
                        child: const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.navyDeep),
                      ),
                      const SizedBox(width: AppSpacing.sm12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title, style: AppTypography.body(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                              widget.body,
                              style: AppTypography.body(fontSize: 14, color: AppColors.creamDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
