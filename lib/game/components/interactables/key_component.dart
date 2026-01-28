import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

class KeyComponent extends PositionComponent with HasGameReference<PixelClashGame> {
  KeyComponent({
    required super.position,
    this.pickupTime = 0.8,
    this.interactRadius = 56,
  });

  final double pickupTime;
  final double interactRadius;

  bool _picked = false;
  double _progress = 0;
  double _pulse = 0;

  final Paint _fill = Paint()..color = const Color(0xFFFFC107);
  final Paint _border = Paint()
    ..color = const Color(0xAA000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _hole = Paint()..color = const Color(0xFF5D4037);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(28, 18);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_picked) return;

    _pulse += dt;

    final p = game.player;
    if (p == null || p.isRemoving) return;

    final dist2 = p.position.distanceToSquared(position);
    final r2 = interactRadius * interactRadius;

    if (dist2 <= r2) {
      _progress = min(pickupTime, _progress + dt);
      if (_progress >= pickupTime) {
        _picked = true;
        _progress = pickupTime;
        _collect();
      }
    } else {
      _progress = max(0, _progress - dt * 1.2);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final glow = 0.10 + 0.15 * (sin(_pulse * 5) * 0.5 + 0.5);
    final glowPaint = Paint()..color = const Color(0xFFFFF59D).withValues(alpha: glow);
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.5), size.y * 0.55, glowPaint);

    final headCenter = Offset(size.x * 0.3, size.y * 0.5);
    final headRadius = size.y * 0.35;
    canvas.drawCircle(headCenter, headRadius, _fill);
    canvas.drawCircle(headCenter, headRadius, _border);

    final shaftHeight = size.y * 0.22;
    final shaftY = size.y * 0.5 - shaftHeight / 2;
    final shaftX = size.x * 0.42;
    final shaftW = size.x * 0.42;
    canvas.drawRect(Rect.fromLTWH(shaftX, shaftY, shaftW, shaftHeight), _fill);

    final toothW = size.x * 0.10;
    final toothH = size.y * 0.28;
    final toothX = shaftX + shaftW - toothW;
    canvas.drawRect(Rect.fromLTWH(toothX, shaftY - toothH + 1, toothW, toothH), _fill);
    canvas.drawRect(
      Rect.fromLTWH(toothX - toothW * 1.25, shaftY - toothH * 0.45, toothW, toothH * 0.45),
      _fill,
    );

    canvas.drawCircle(headCenter, headRadius * 0.4, _hole);

    if (!_picked && _progress > 0) {
      final t = (_progress / pickupTime).clamp(0.0, 1.0);
      final center = Offset(size.x / 2, -12);
      const radius = 10.0;

      final bg = Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final fg = Paint()
        ..color = const Color(0xFFFFD54F)
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

  void _collect() {
    game.onKeyCollected();
    removeFromParent();
  }
}
