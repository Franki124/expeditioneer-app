import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/radii.dart';

/// The default card chrome: a solid panel fill with a subtle border and
/// standard rounded corners. Replaces the repeated `Container(navyPanel,
/// AppRadii.card)` pattern used across the app.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.highlighted = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: highlighted ? AppColors.goldBright : AppColors.gold.withValues(alpha: 0.28),
      width: highlighted ? 1.5 : 1,
    );

    if (onTap == null) {
      return Container(
        decoration: BoxDecoration(color: AppColors.navyPanel, borderRadius: AppRadii.card, border: border),
        padding: padding,
        child: child,
      );
    }

    return Material(
      color: AppColors.navyPanel,
      borderRadius: AppRadii.card,
      child: InkWell(
        borderRadius: AppRadii.card,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(borderRadius: AppRadii.card, border: border),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
