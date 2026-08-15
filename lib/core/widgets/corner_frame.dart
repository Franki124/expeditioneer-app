import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Four L-shaped gold corner brackets — a surveyor's-frame motif reserved
/// for "hero" panels (today's quests, stats), not every card. Originally a
/// private painter in `viewfinder.dart`; generalized here so both can share it.
class CornerBracketsPainter extends CustomPainter {
  const CornerBracketsPainter({this.length = 14, this.strokeWidth = 2, this.color = AppColors.gold});

  final double length;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    void corner(Offset origin, Offset dx, Offset dy) {
      canvas.drawLine(origin, origin + dx, paint);
      canvas.drawLine(origin, origin + dy, paint);
    }

    corner(Offset.zero, Offset(length, 0), Offset(0, length));
    corner(Offset(size.width, 0), Offset(-length, 0), Offset(0, length));
    corner(Offset(0, size.height), Offset(length, 0), Offset(0, -length));
    corner(Offset(size.width, size.height), Offset(-length, 0), Offset(0, -length));
  }

  @override
  bool shouldRepaint(covariant CornerBracketsPainter oldDelegate) =>
      oldDelegate.length != length || oldDelegate.strokeWidth != strokeWidth || oldDelegate.color != color;
}

/// A hero panel: solid panel fill, a hairline gold border, and
/// [CornerBracketsPainter] corner marks laid over the top.
class CornerFrame extends StatelessWidget {
  const CornerFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.cornerLength = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double cornerLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyPanel2,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: CornerBracketsPainter(length: cornerLength))),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
