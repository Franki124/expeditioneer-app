import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/diamond_marker.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/domain/journal.dart';

String _tagFor(String type) => switch (type) {
      QuestType.gestral => 'Gestral',
      QuestType.quiz => 'Quiz',
      _ => 'Journal',
    };

class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.journal,
    this.unlocked = false,
    this.inProgress = false,
    this.onTap,
  });

  final Journal journal;
  final bool unlocked;

  /// Quiz-only: found and started, but not every question answered yet.
  final bool inProgress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tag = _tagFor(journal.type);
    if (!unlocked && !inProgress) {
      return GestureDetector(
        onTap: onTap,
        child: LockedCardBox(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DiamondMarker(
                  size: 34,
                  color: AppColors.locked,
                  glow: true,
                  child: const Icon(Icons.lock_outline, color: AppColors.locked, size: 16),
                ),
                const SizedBox(height: AppSpacing.sm12),
                Text(
                  'Find this $tag quest',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(fontSize: 13, color: AppColors.locked),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm12),
      highlighted: inProgress,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tag, style: AppTypography.label(fontSize: 13)),
              if (journal.type == QuestType.quiz && journal.difficulty != null) ...[
                const SizedBox(width: AppSpacing.xs4),
                Text('· ${journal.difficulty}', style: AppTypography.body(fontSize: 13, color: AppColors.creamDim)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs4),
          Text(journal.title, style: AppTypography.body(fontWeight: FontWeight.w700)),
          if (inProgress) ...[
            const SizedBox(height: AppSpacing.xs4),
            Text('Continue quiz', style: AppTypography.label(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class LockedCardBox extends StatelessWidget {
  const LockedCardBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.card,
      child: ShimmerBox(
        color: AppColors.locked,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navyPanel.withValues(alpha: 0.7),
            borderRadius: AppRadii.card,
            border: Border.all(color: AppColors.locked.withValues(alpha: 0.35)),
          ),
          child: child,
        ),
      ),
    );
  }
}
