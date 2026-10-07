import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../events/cubit/joined_event_cubit.dart';
import '../data/pack_file_store.dart';

/// Shows an event image from the downloaded event pack when it's on the
/// device, otherwise from the network, and a placeholder while it loads or
/// when it can't be loaded (no signal and never downloaded).
class PackImage extends StatelessWidget {
  const PackImage({
    super.key,
    required this.url,
    this.label,
    this.fit = BoxFit.contain,
    this.backgroundColor = AppColors.navyPanel,
  });

  final String url;

  /// Shown on the placeholder, e.g. the quest type.
  final String? label;
  final BoxFit fit;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final eventId = context.select<JoinedEventCubit, String?>((cubit) => cubit.state.joinedEventId);
    final stored = eventId == null ? null : context.read<PackFileStore>().imageFor(eventId, url);

    Widget placeholder({required bool failed}) =>
        PackImagePlaceholder(label: label, failed: failed, backgroundColor: backgroundColor);

    final image = stored != null
        ? Image(
            image: stored,
            width: double.infinity,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => placeholder(failed: true),
          )
        : Image.network(
            packImageUrl(url),
            width: double.infinity,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => placeholder(failed: true),
            loadingBuilder: (context, child, progress) => progress == null ? child : placeholder(failed: false),
          );
    return ColoredBox(color: backgroundColor, child: image);
  }
}

class PackImagePlaceholder extends StatelessWidget {
  const PackImagePlaceholder({super.key, this.label, this.failed = false, this.backgroundColor = AppColors.navyPanel});

  final String? label;

  /// The image couldn't be loaded, as opposed to still loading.
  final bool failed;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(failed ? Icons.cloud_off_outlined : Icons.image_outlined, color: AppColors.creamDim, size: 28),
              if (label != null) ...[
                const SizedBox(height: AppSpacing.xs8),
                Text(label!, style: AppTypography.body(color: AppColors.creamDim)),
              ],
              if (failed) ...[
                const SizedBox(height: AppSpacing.xs4),
                Text(
                  "The picture will appear when you're back online.",
                  textAlign: TextAlign.center,
                  style: AppTypography.body(fontSize: 13, color: AppColors.creamDim),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
