import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/config/game_constants.dart';

/// Мир/карта.
/// В 0.1 это большой прямоугольник + сетка для ориентира.
class WorldMap extends World {
  final Vector2 mapSize = Vector2(GameConstants.mapWidth, GameConstants.mapHeight);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(_MapBackground(size: mapSize));
  }

  /// Ограничение позиции внутри карты.
  Vector2 clampToMap(Vector2 p) {
    final x = p.x.clamp(32.0, mapSize.x - 32.0);
    final y = p.y.clamp(32.0, mapSize.y - 32.0);
    return Vector2(x, y);
  }
}

/// Фон карты (временно).
class _MapBackground extends PositionComponent {
  _MapBackground({required Vector2 size}) {
    this.size = size;
    position = Vector2.zero();
    anchor = Anchor.topLeft;
  }

  final _paintFill = Paint()..color = const Color(0xFF222222);
  final _paintBorder = Paint()
    ..color = Colors.white24
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawRect(size.toRect(), _paintFill);
    canvas.drawRect(size.toRect(), _paintBorder);

    // Сетка (для дебага и ощущения масштаба).
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    const step = 200.0;

    for (double x = 0; x < size.x; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }
  }
}
