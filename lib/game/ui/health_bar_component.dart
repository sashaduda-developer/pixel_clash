import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Универсальная полоска HP (для врагов/объектов).
/// Важно: поля не называем width/height, потому что они уже есть у PositionComponent.
class HealthBarComponent extends PositionComponent {
  HealthBarComponent({
    required this.getCurrent,
    required this.getMax,
    this.barWidth = 28,
    this.barHeight = 4,
  });

  final int Function() getCurrent;
  final int Function() getMax;

  final double barWidth;
  final double barHeight;

  final Paint _bg = Paint()..color = const Color(0x66000000);
  final Paint _fg = Paint()..color = const Color(0xFFE53935);
  final Paint _border = Paint()
    ..color = const Color(0x66FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(barWidth, barHeight);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final maxHp = getMax();
    final curHp = getCurrent();

    final ratio = maxHp <= 0 ? 0.0 : (curHp / maxHp).clamp(0.0, 1.0);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      _bg,
    );

    if (ratio > 0) {
      final fill = Rect.fromLTWH(0, 0, size.x * ratio, size.y);
      canvas.drawRRect(
        RRect.fromRectAndRadius(fill, const Radius.circular(2)),
        _fg,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      _border,
    );
  }
}
