import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Repeating diagonal tinted gradient sweep over [child] — the
/// `shimmerGold`/`shimmerSlide` locked-card treatment from the design.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, required this.child, this.color = AppColors.gold});

  final Widget child;
  final Color color;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final sweep = _controller.value * 2 - 0.5;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                widget.color.withValues(alpha: 0.45),
                Colors.transparent,
              ],
              stops: [
                (sweep - 0.12).clamp(0.0, 1.0),
                sweep.clamp(0.0, 1.0),
                (sweep + 0.12).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
