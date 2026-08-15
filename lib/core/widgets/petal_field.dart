import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A single petal's loop: constant left-to-right drift plus a gentle bob
/// and slow tumble, all keyed off a shared clock via [phaseAt] so each
/// petal wraps independently and never resets in lockstep with the others.
class _PetalSpec {
  _PetalSpec({
    required this.laneY,
    required this.size,
    required this.isRed,
    required this.phase,
    required this.speed,
    required this.bobAmplitude,
    required this.bobPhase,
    required this.spin,
  });

  final double laneY;
  final double size;
  final bool isRed;
  final double phase;
  final double speed;
  final double bobAmplitude;
  final double bobPhase;
  final double spin;

  double phaseAt(double clock) => (clock * speed + phase) % 1.0;
}

List<_PetalSpec> _generateSpecs(int count) {
  final random = math.Random(11);
  return List.generate(count, (_) {
    return _PetalSpec(
      laneY: random.nextDouble(),
      size: 7 + random.nextDouble() * 10,
      isRed: random.nextDouble() < 0.6,
      phase: random.nextDouble(),
      speed: 0.7 + random.nextDouble() * 0.6,
      bobAmplitude: 0.015 + random.nextDouble() * 0.035,
      bobPhase: random.nextDouble() * math.pi * 2,
      spin: (0.5 + random.nextDouble() * 1.5) * (random.nextBool() ? 1 : -1),
    );
  });
}

/// A slow, endlessly-looping field of red and white petals drifting
/// left-to-right — an ambient background for screens with time to spare
/// (e.g. login, before a player has joined anything). Self-contained: owns
/// its own repeating animation and ignores pointer events, so it's safe to
/// drop straight into a `Stack` behind real content.
class PetalField extends StatefulWidget {
  const PetalField({super.key, this.petalCount = 16, this.loopDuration = const Duration(seconds: 26)});

  final int petalCount;
  final Duration loopDuration;

  @override
  State<PetalField> createState() => _PetalFieldState();
}

class _PetalFieldState extends State<PetalField> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_PetalSpec> _specs;

  @override
  void initState() {
    super.initState();
    _specs = _generateSpecs(widget.petalCount);
    _controller = AnimationController(vsync: this, duration: widget.loopDuration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _PetalPainter(clock: _controller.value, specs: _specs),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _PetalPainter extends CustomPainter {
  _PetalPainter({required this.clock, required this.specs});

  final double clock;
  final List<_PetalSpec> specs;

  static const _red = Color(0xFFB1394A);
  static const _white = Color(0xFFF3ECDD);

  @override
  void paint(Canvas canvas, Size size) {
    for (final spec in specs) {
      final t = spec.phaseAt(clock);
      final x = (-0.12 + t * 1.24) * size.width;
      final bob = math.sin(t * math.pi * 2 + spec.bobPhase) * spec.bobAmplitude * size.height;
      final y = spec.laneY * size.height + bob;

      double opacity;
      if (t < 0.08) {
        opacity = t / 0.08;
      } else if (t > 0.92) {
        opacity = (1 - t) / 0.08;
      } else {
        opacity = 1;
      }
      if (opacity <= 0) continue;

      final paint = Paint()..color = (spec.isRed ? _red : _white).withValues(alpha: opacity * 0.6);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * spec.spin * math.pi * 2);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: spec.size, height: spec.size * 0.6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter oldDelegate) => oldDelegate.clock != clock;
}
