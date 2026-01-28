import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

class PortalComponent extends PositionComponent with HasGameReference<PixelClashGame> {
  PortalComponent({
    required super.position,
    this.captureTime = 2.4,
    this.interactRadius = 80,
  });

  final double captureTime;
  final double interactRadius;

  bool _locked = true;
  bool _captured = false;
  bool _open = false;
  bool _entering = false;
  double _progress = 0;
  double _pulse = 0;

  void setLocked(bool value) {
    _locked = value;
    if (value) {
      _progress = 0;
    }
  }

  void setOpen(bool value) => _open = value;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(72, 72);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _pulse += dt;

    final p = game.player;
    if (p == null || p.isRemoving) return;

    final dist2 = p.position.distanceToSquared(position);
    final r2 = interactRadius * interactRadius;
    if (dist2 > r2) {
      if (!_captured) {
        _progress = max(0, _progress - dt * 1.2);
      }
      return;
    }

    if (_locked) return;

    if (!_captured) {
      _progress = min(captureTime, _progress + dt);
      if (_progress >= captureTime) {
        _captured = true;
        _progress = captureTime;
        game.onPortalCaptured();
      }
      return;
    }

    if (_open && !_entering) {
      _entering = true;
      game.onPortalEntered();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final color = _portalColor();
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x * 0.45;

    final glow = 0.18 + 0.18 * (sin(_pulse * 3.2) * 0.5 + 0.5);
    final glowPaint = Paint()..color = color.withValues(alpha: glow);
    canvas.drawCircle(center, radius + 8, glowPaint);

    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, ringPaint);

    final innerPaint = Paint()..color = color.withValues(alpha: 0.15);
    canvas.drawCircle(center, radius - 8, innerPaint);

    if (!_captured && !_locked && _progress > 0) {
      final t = (_progress / captureTime).clamp(0.0, 1.0);
      final fg = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 12),
        -pi / 2,
        pi * 2 * t,
        false,
        fg,
      );
    }

    if (_shouldShowKeyHint()) {
      _renderKeyHint(canvas);
    }
  }

  Color _portalColor() {
    if (_locked) return const Color(0xFF616161);
    if (_open) return const Color(0xFF26C6DA);
    if (_captured) return const Color(0xFFFFA726);
    return const Color(0xFF42A5F5);
  }

  bool _shouldShowKeyHint() {
    if (!_locked) return false;
    final p = game.player;
    if (p == null || p.isRemoving) return false;
    final r = interactRadius * 1.15;
    return p.position.distanceToSquared(position) <= r * r;
  }

  void _renderKeyHint(Canvas canvas) {
    final text = '${game.keysFound.value}/${PixelClashGame.requiredKeys}';
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    const paddingX = 10.0;
    const paddingY = 6.0;
    const spacing = 6.0;
    const iconW = 14.0;
    const iconH = 10.0;

    final contentH = max(iconH, tp.height);
    final boxW = paddingX * 2 + iconW + spacing + tp.width;
    final boxH = paddingY * 2 + contentH;

    final x = size.x / 2 - boxW / 2;
    final y = -boxH - 16;
    final rect = Rect.fromLTWH(x, y, boxW, boxH);

    final bg = Paint()..color = Colors.black.withValues(alpha: 0.7);
    final border = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), bg);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), border);

    final iconX = x + paddingX;
    final iconY = y + paddingY + (contentH - iconH) / 2;
    _drawKeyIcon(canvas, Offset(iconX, iconY), iconW, iconH);

    final textX = iconX + iconW + spacing;
    final textY = y + paddingY + (contentH - tp.height) / 2;
    tp.paint(canvas, Offset(textX, textY));
  }

  void _drawKeyIcon(Canvas canvas, Offset topLeft, double w, double h) {
    final fill = Paint()..color = const Color(0xFFFFC107);
    final border = Paint()
      ..color = const Color(0xAA000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final hole = Paint()..color = const Color(0xFF5D4037);

    final headCenter = Offset(topLeft.dx + h * 0.45, topLeft.dy + h / 2);
    final headRadius = h * 0.35;
    canvas.drawCircle(headCenter, headRadius, fill);
    canvas.drawCircle(headCenter, headRadius, border);
    canvas.drawCircle(headCenter, headRadius * 0.45, hole);

    final shaftX = topLeft.dx + h * 0.75;
    final shaftY = topLeft.dy + h * 0.38;
    final shaftW = w - (shaftX - topLeft.dx);
    final shaftH = h * 0.24;
    canvas.drawRect(Rect.fromLTWH(shaftX, shaftY, shaftW, shaftH), fill);

    final toothW = w * 0.14;
    final toothH = h * 0.28;
    final toothX = shaftX + shaftW - toothW;
    canvas.drawRect(Rect.fromLTWH(toothX, shaftY - toothH + 0.5, toothW, toothH), fill);
  }
}
