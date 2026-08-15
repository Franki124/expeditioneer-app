import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A horizontal rule that fades to transparent at both ends instead of
/// stopping cleanly.
class FadingDivider extends StatelessWidget {
  const FadingDivider({super.key, this.height = 1, this.color = AppColors.gold});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, color.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
    );
  }
}
