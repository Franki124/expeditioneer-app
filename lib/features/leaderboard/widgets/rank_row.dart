import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/diamond_marker.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/domain/participant.dart';

class RankRow extends StatelessWidget {
  const RankRow({super.key, required this.rank, required this.participant, this.highlight = false});

  final int rank;
  final Participant participant;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm12, vertical: AppSpacing.xs10),
        highlighted: highlight,
        child: Row(
          children: [
            DiamondMarker(
              size: 30,
              filled: isTop3,
              glow: isTop3,
              child: Text(
                '$rank',
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isTop3 ? AppColors.navyDeep : AppColors.creamDim,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm12),
            Expanded(
              child: Text(participant.displayName, style: AppTypography.body(fontWeight: FontWeight.w700)),
            ),
            Text(
              '${participant.totalPoints} pts',
              style: AppTypography.body(fontWeight: FontWeight.w700, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}
