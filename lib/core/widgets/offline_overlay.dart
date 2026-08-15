import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../utils/connectivity_cubit.dart';

/// Small cross-cutting banner, not a full screen — slides down from the top
/// whenever [ConnectivityCubit] reports offline, mounted once above the
/// router's whole widget tree via `MaterialApp.router`'s `builder`.
class OfflineOverlay extends StatelessWidget {
  const OfflineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityCubit>().state;
    return IgnorePointer(
      ignoring: isOnline,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          offset: isOnline ? const Offset(0, -1) : Offset.zero,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md20,
                vertical: AppSpacing.xs10,
              ),
              color: AppColors.error,
              child: Text(
                "You're offline — some features may not work.",
                textAlign: TextAlign.center,
                style: AppTypography.body(fontWeight: FontWeight.w700, color: AppColors.navyDeep),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
