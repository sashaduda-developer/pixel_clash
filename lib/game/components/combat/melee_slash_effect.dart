import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Короткий визуальный "слэш" для удара мечом.
class MeleeSlashEffect extends PositionComponent {
  MeleeSlashEffect({
    required super.position,
    required this.angle,
    this.length = 36,
    this.thickness = 4,
    this.color = const Color(0xFFFFF3E0),
    this.maxAlpha = 0.85,
    this.lifeSeconds = 0.12,
  });

  @override
  final double angle;
  final double length;
  final double thickness;
  final Color color;
  final double maxAlpha;
  final double lifeSeconds;

  double _life = 0;
  late final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(length);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    if (_life >= lifeSeconds) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final t = (1 - (_life / lifeSeconds)).clamp(0.0, 1.0);
    _paint
      ..color = color.withValues(alpha: maxAlpha * t)
      ..strokeWidth = thickness;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(angle);
    canvas.drawLine(
      const Offset(0, 0),
      Offset(length * 0.8, 0),
      _paint,
    );
    canvas.restore();
  }
}
