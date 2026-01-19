import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

/// Сундук: если игрок рядом N секунд — открывается и выдаёт награду.
///
/// Сейчас награда будет тестовая (позже заменим на LootTable).
class ChestComponent extends PositionComponent with HasGameReference<PixelClashGame> {
  ChestComponent({
    required super.position,
    this.openTime = 2.0,
    this.interactRadius = 54,
  });

  final double openTime;
  final double interactRadius;

  bool _opened = false;
  double _progress = 0;

  final Paint _body = Paint()..color = const Color(0xFF8D6E63);
  final Paint _border = Paint()
    ..color = const Color(0xAA000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(34, 26);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_opened) return;

    final p = game.player;
    if (p == null || p.isRemoving) return;

    final dist2 = p.position.distanceToSquared(position);
    final r2 = interactRadius * interactRadius;

    if (dist2 <= r2) {
      _progress = min(openTime, _progress + dt);
      if (_progress >= openTime) {
        _opened = true;
        _progress = openTime;
        _open();
      }
    } else {
      _progress = max(0, _progress - dt * 1.2);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), _body);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), _border);

    // Прогресс открытия (кольцо над сундуком)
    if (!_opened && _progress > 0) {
      final t = (_progress / openTime).clamp(0.0, 1.0);

      final center = Offset(size.x / 2, -10);
      const radius = 10.0;

      final bg = Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final fg = Paint()
        ..color = const Color(0xFF66BB6A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, bg);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        pi * 2 * t,
        false,
        fg,
      );
    }
  }

  void _open() {
    // Пока просто сигналим игре: "сундук открыт".
    // Позже здесь будет конкретный loot roll.
    game.onChestOpened();
    removeFromParent();
  }
}
