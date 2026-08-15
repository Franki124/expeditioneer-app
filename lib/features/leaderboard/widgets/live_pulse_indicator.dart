import 'package:flutter/material.dart';

import '../../../core/widgets/diamond_marker.dart';
import '../../../theme/typography.dart';

/// Pulsing "LIVE" badge — matches the source design's `shimmerGold` opacity
/// pulse (0.55 <-> 1).
class LivePulseIndicator extends StatefulWidget {
  const LivePulseIndicator({super.key});

  @override
  State<LivePulseIndicator> createState() => _LivePulseIndicatorState();
}

class _LivePulseIndicatorState extends State<LivePulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
          child: const DiamondMarker(size: 9, filled: true, glow: true),
        ),
        const SizedBox(width: 8),
        Text('live', style: AppTypography.label(fontSize: 14)),
      ],
    );
  }
}
