import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/diamond_marker.dart';
import '../../routing/route_paths.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'cubit/onboarding_cubit.dart';
import 'onboarding_slide_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  bool get _isLastSlide => _page == onboardingSlides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<OnboardingCubit>().markSeen();
    context.go(RoutePaths.home);
  }

  void _next() {
    if (_isLastSlide) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm12),
                child: TextButton(
                  onPressed: _finish,
                  child: Text('skip', style: AppTypography.label(fontSize: 15, color: AppColors.creamDim)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingSlides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => _OnboardingSlide(data: onboardingSlides[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < onboardingSlides.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DiamondMarker(
                      size: i == _page ? 12 : 9,
                      filled: i == _page,
                      color: AppColors.gold,
                      borderColor: i <= _page
                          ? AppColors.goldBright.withValues(alpha: 0.8)
                          : AppColors.gold.withValues(alpha: 0.35),
                      glow: i == _page,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md20),
              child: AppButton(
                label: _isLastSlide ? 'Start the expedition' : 'Next',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});

  final OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DiamondMarker(
            size: 88,
            glow: true,
            child: Icon(data.icon, color: AppColors.gold, size: 34),
          ),
          const SizedBox(height: AppSpacing.lg32),
          Text(
            data.headline,
            style: AppTypography.display(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm12),
          Text(
            data.body,
            style: AppTypography.body(color: AppColors.creamDim),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
