import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';

enum AppButtonVariant { primary, secondary, ghost }

/// A plain rounded-rect button — solid-fill primary, outlined secondary,
/// text-only ghost. Standard app-button shape (`AppRadii.button`), not a
/// stylized cut-corner one.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    late final Color borderColor;
    late final Color textColor;
    late final Color fillColor;
    switch (variant) {
      case AppButtonVariant.primary:
        borderColor = Colors.transparent;
        fillColor = disabled ? AppColors.gold.withValues(alpha: 0.35) : AppColors.gold;
        textColor = AppColors.navyDeep;
      case AppButtonVariant.secondary:
        borderColor = AppColors.gold.withValues(alpha: disabled ? 0.2 : 0.5);
        textColor = disabled ? AppColors.creamDim.withValues(alpha: 0.5) : AppColors.cream;
        fillColor = Colors.transparent;
      case AppButtonVariant.ghost:
        borderColor = Colors.transparent;
        textColor = disabled ? AppColors.creamDim.withValues(alpha: 0.5) : AppColors.gold;
        fillColor = Colors.transparent;
    }

    return Material(
      color: fillColor,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.button, side: BorderSide(color: borderColor)),
      child: InkWell(
        borderRadius: AppRadii.button,
        onTap: disabled ? null : onPressed,
        child: Container(
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
              : Text(label, style: AppTypography.label(fontSize: 16, color: textColor)),
        ),
      ),
    );
  }
}
