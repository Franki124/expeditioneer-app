import 'package:flutter/material.dart';

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.icon,
    required this.headline,
    required this.body,
  });

  final IconData icon;
  final String headline;
  final String body;
}

const onboardingSlides = [
  OnboardingSlideData(
    icon: Icons.menu_book_outlined,
    headline: 'Find every journal',
    body: 'Hidden markers are scattered across the festival grounds, each hiding a page of the expedition journal.',
  ),
  OnboardingSlideData(
    icon: Icons.qr_code_scanner,
    headline: 'Scan to reveal',
    body: 'Point your camera at a marker to reveal what it holds — a journal page, or a Gestral companion.',
  ),
  OnboardingSlideData(
    icon: Icons.emoji_events_outlined,
    headline: 'Complete your expedition',
    body: 'Collect every page to complete your expedition and climb the live leaderboard.',
  ),
];
