import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A rotated-45° square — the bullet/checkbox/progress-node motif used in
/// place of plain dots throughout the theme.
class DiamondMarker extends StatelessWidget {
  const DiamondMarker({
    super.key,
    this.size = 12,
    this.filled = false,
    this.color = AppColors.gold,
    this.borderColor,
    this.glow = false,
    this.child,
  });

  final double size;
  final bool filled;
  final Color color;
  final Color? borderColor;
  final bool glow;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          border: Border.all(color: borderColor ?? color.withValues(alpha: 0.7)),
          boxShadow: glow ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14)] : null,
        ),
        child: child == null ? null : Transform.rotate(angle: -math.pi / 4, child: child),
      ),
    );
  }
}
