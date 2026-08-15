import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

class JournalCompleteBanner extends StatelessWidget {
  const JournalCompleteBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md20),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md20),
        highlighted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Journal complete!', style: AppTypography.display(fontSize: 20, color: AppColors.gold)),
            const SizedBox(height: AppSpacing.xs4),
            Text(
              'Come back to the village for your prize!',
              style: AppTypography.body(color: AppColors.creamDim),
            ),
          ],
        ),
      ),
    );
  }
}
