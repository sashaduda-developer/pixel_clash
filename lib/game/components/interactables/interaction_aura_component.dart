import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Пульсирующая аура вокруг интерактивных объектов.
class InteractionAuraComponent extends PositionComponent {
  InteractionAuraComponent({
    required this.radius,
    required this.color,
    this.pulseSpeed = 2.2,
    this.baseAlpha = 0.16,
    this.pulseAlpha = 0.40,
  });

  final double radius;
  final Color color;
  final double pulseSpeed;
  final double baseAlpha;
  final double pulseAlpha;

  double _time = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(radius * 2);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final t = (sin(_time * pulseSpeed) * 0.5 + 0.5).clamp(0.0, 1.0);

    final ringRadius = radius * (0.92 + 0.08 * t);
    final glowRadius = ringRadius + 4 * t;
    final fillRadius = ringRadius * 0.92;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: (baseAlpha + pulseAlpha * 0.6 * t).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 + 4 * t
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final fillPaint = Paint()
      ..color = color.withValues(alpha: (baseAlpha * 0.9 + pulseAlpha * 0.25 * t).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = color.withValues(alpha: (baseAlpha + pulseAlpha * t).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + 1.2 * t;

    canvas.drawCircle(center, fillRadius, fillPaint);
    canvas.drawCircle(center, glowRadius, glowPaint);
    canvas.drawCircle(center, ringRadius, ringPaint);
  }
}
