import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_button.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

class CameraAccessOffScreen extends StatelessWidget {
  const CameraAccessOffScreen({
    super.key,
    required this.onOpenSettings,
    required this.onTryAgain,
  });

  /// No-op on web — `permission_handler` can't open browser settings, there's
  /// no OS-level deep link to send the player to. Not called there; see below.
  final VoidCallback onOpenSettings;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: AppColors.creamDim, size: 48),
            const SizedBox(height: AppSpacing.md20),
            Text(
              'Camera access is off',
              style: AppTypography.display(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs8),
            Text(
              kIsWeb
                  ? "Allow camera access via your browser's address-bar icon, then try again."
                  : 'Enable camera access to scan QR codes around the venue.',
              style: AppTypography.body(color: AppColors.creamDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md20),
            if (!kIsWeb) ...[
              AppButton(label: 'Open Settings', onPressed: onOpenSettings),
              const SizedBox(height: AppSpacing.sm12),
            ],
            TextButton(
              onPressed: onTryAgain,
              child: Text('try again', style: AppTypography.label(fontSize: 15, color: AppColors.creamDim)),
            ),
          ],
        ),
      ),
    );
  }
}
