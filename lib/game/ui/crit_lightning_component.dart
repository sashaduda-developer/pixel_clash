import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Короткая и яркая молния для крита.
/// Делается максимально дешево: рисуем ломаную линию Canvas'ом.
class CritLightningComponent extends PositionComponent {
  CritLightningComponent({
    required super.position,
    this.lifeTime = 0.18,
    this.boltHeight = 32, // ✅ НЕ height
  }) {
    anchor = Anchor.center;
    priority = 100000; // ✅ поверх всего
    _generate();
  }

  final double lifeTime;

  /// Высота "молнии" в локальных координатах компонента.
  final double boltHeight;

  late List<Offset> _points;

  double _life = 0;

  void _generate() {
    final rng = Random();

    // Ломаная: сверху вниз, с "зигзагом"
    const segments = 7;
    final step = boltHeight / (segments - 1);

    _points = List.generate(segments, (i) {
      final y = -boltHeight / 2 + i * step;
      final x = (rng.nextDouble() * 2 - 1) * 10; // ширина зигзага
      return Offset(x, y);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;

    // Чуть "дёргаем" молнию, чтобы ощущалась живой
    if (_life < lifeTime * 0.6) {
      _generate();
    }

    if (_life >= lifeTime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final t = (_life / lifeTime).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);

    // Основная линия
    final paintMain = Paint()
      ..color = const Color(0xFFFFEB3B).withValues(alpha: alpha)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Белый "блик" внутри — читается супер
    final paintGlow = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.65)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(_points.first.dx, _points.first.dy);
    for (final p in _points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(path, paintMain);
    canvas.drawPath(path, paintGlow);
  }
}
