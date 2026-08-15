import 'package:flutter/material.dart';

import '../../../core/utils/countdown_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/domain/event.dart';

class JoinedEventCard extends StatelessWidget {
  const JoinedEventCard({super.key, required this.event, required this.collectedCount});

  final Event event;
  final int collectedCount;

  @override
  Widget build(BuildContext context) {
    final ended = !event.isLive;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.name, style: AppTypography.display(fontSize: 20)),
          const SizedBox(height: AppSpacing.xs4),
          Text(event.location, style: AppTypography.body(color: AppColors.creamDim)),
          const SizedBox(height: AppSpacing.sm12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$collectedCount / ${event.journalCount} collected',
                style: AppTypography.body(fontWeight: FontWeight.w700, color: AppColors.gold),
              ),
              Text(
                ended ? 'Event ended' : formatCountdown(event.endAt),
                style: AppTypography.body(
                  color: ended ? AppColors.error : AppColors.creamDim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
