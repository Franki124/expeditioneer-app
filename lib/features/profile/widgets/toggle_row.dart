import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm14, vertical: AppSpacing.xs8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.body()),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}
