import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.display(fontSize: 20)),
            const SizedBox(height: AppSpacing.xs4),
            Text(label, style: AppTypography.label(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
