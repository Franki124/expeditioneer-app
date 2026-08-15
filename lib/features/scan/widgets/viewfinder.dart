import 'package:flutter/material.dart';

import '../../../core/widgets/corner_frame.dart';
import '../../../theme/colors.dart';

/// Corner-bracket viewfinder with an animated scan line, sweeping top 6% to
/// 92% and back — matches the source design's `scanLine` keyframes.
class Viewfinder extends StatefulWidget {
  const Viewfinder({super.key});

  @override
  State<Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<Viewfinder> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _position = Tween<double>(begin: 0.06, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: CornerBracketsPainter(length: 28, strokeWidth: 3)),
              ),
              AnimatedBuilder(
                animation: _position,
                builder: (context, child) {
                  return Positioned(
                    top: _position.value * constraints.maxHeight,
                    left: 0,
                    right: 0,
                    child: Container(height: 2, color: AppColors.gold),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
