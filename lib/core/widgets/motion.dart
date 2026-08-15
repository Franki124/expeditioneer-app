import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Fade + 8px slide-up on entry — wrap a screen's main content in this.
/// Mirrors the mockup's `mfade` keyframes (opacity 0→1, translateY 8px→0).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.duration = const Duration(milliseconds: 350)});

  final Widget child;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..forward();
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _progress.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _progress.value) * 8),
            child: child,
          ),
        );
      },
    );
  }
}

/// A dialog presented with fade + scale-from-0.96 instead of the default
/// Material dialog transition — mirrors the mockup's `mdlg` keyframes.
/// [builder] should return the same `AlertDialog`/`Dialog` content that
/// would otherwise go straight into `showDialog`'s own builder.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.navyDeep.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return Opacity(
        opacity: curved.value,
        child: Transform.scale(scale: 0.96 + curved.value * 0.04, child: child),
      );
    },
  );
}
