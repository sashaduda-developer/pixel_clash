import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

/// Алтарь: когда игрок рядом N секунд — выдаёт магическую награду.
class AltarComponent extends PositionComponent with HasGameReference<PixelClashGame> {
  AltarComponent({
    required super.position,
    this.openTime = 2.2,
    this.interactRadius = 58,
  });

  final double openTime;
  final double interactRadius;

  bool _activated = false;
  double _progress = 0;
  double _pulse = 0;

  final Paint _body = Paint()..color = const Color(0xFF5C6BC0);
  final Paint _border = Paint()
    ..color = const Color(0xAA000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(34, 34);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_activated) return;

    _pulse += dt;

    final p = game.player;
    if (p == null || p.isRemoving) return;

    final dist2 = p.position.distanceToSquared(position);
    final r2 = interactRadius * interactRadius;

    if (dist2 <= r2) {
      _progress = min(openTime, _progress + dt);
      if (_progress >= openTime) {
        _activated = true;
        _progress = openTime;
        _activate();
      }
    } else {
      _progress = max(0, _progress - dt * 1.2);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), _body);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), _border);

    // Светящийся пульс
    final glow = 0.10 + 0.10 * (sin(_pulse * 4) * 0.5 + 0.5);
    final glowPaint = Paint()..color = const Color(0xFF9FA8DA).withValues(alpha: glow);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 20, glowPaint);

    // Прогресс активации (кольцо)
    if (!_activated && _progress > 0) {
      final t = (_progress / openTime).clamp(0.0, 1.0);

      final center = Offset(size.x / 2, -12);
      const radius = 10.0;

      final bg = Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final fg = Paint()
        ..color = const Color(0xFF9FA8DA)
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

  void _activate() {
    game.onAltarActivated();
    removeFromParent();
  }
}
