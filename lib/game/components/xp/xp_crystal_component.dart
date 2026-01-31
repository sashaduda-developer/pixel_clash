import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

class XpCrystalComponent extends PositionComponent with HasGameReference<PixelClashGame> {
  XpCrystalComponent({
    required super.position,
    required num xp,
    this.magnetRadius = 150,
    this.pickupRadius = 28,
    this.baseSpeed = 26,
    this.pullSpeed = 260,
    this.maxLifeSeconds = 10.0,
    this.blinkDurationSec = 4.0,
  }) : _xp = xp.toDouble();

  final double _xp;
  final double magnetRadius;
  final double pickupRadius;
  final double baseSpeed;
  final double pullSpeed;
  final double maxLifeSeconds;
  final double blinkDurationSec;

  double _life = 0;
  double _bob = 0;
  bool _collected = false;
  double _blinkAlpha = 1.0;

  final Color _coreColor = const Color(0xFF4FC3F7);
  final Color _glowColor = const Color(0xFF4FC3F7);
  final Color _shineColor = const Color(0xFFB3E5FC);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_sizeForXp(_xp));
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isRewardPauseActive) return;
    if (_collected) return;

    _life += dt;
    _bob += dt * 6.0;
    if (maxLifeSeconds > 0 && _life >= maxLifeSeconds) {
      removeFromParent();
      return;
    }

    if (maxLifeSeconds > 0 && blinkDurationSec > 0) {
      final start = maxLifeSeconds - blinkDurationSec;
      if (_life >= start) {
        final phase = (_life - start) * 12.0;
        final t = (sin(phase) * 0.5 + 0.5).clamp(0.0, 1.0);
        _blinkAlpha = 0.25 + 0.75 * t;
      } else {
        _blinkAlpha = 1.0;
      }
    }

    final player = game.player;
    if (player == null || player.isRemoving) return;

    final toPlayer = player.position - position;
    final d2 = toPlayer.length2;
    if (d2 <= pickupRadius * pickupRadius) {
      _collect();
      return;
    }

    if (d2 <= magnetRadius * magnetRadius) {
      final dist = sqrt(d2).clamp(1.0, magnetRadius);
      final pull = pullSpeed * (1.0 - dist / magnetRadius).clamp(0.1, 1.0);
      final dir = toPlayer.normalized();
      position += dir * (baseSpeed + pull) * dt;
    }
  }

  void _collect() {
    if (_collected) return;
    _collected = true;
    game.xpSystem.addXp(_xp);
    removeFromParent();
  }

  double _sizeForXp(num xp) {
    return 4;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bobOffset = sin(_bob) * 1.1;
    final center = Offset(size.x / 2, size.y / 2 + bobOffset);
    final rect = Rect.fromCenter(
      center: center,
      width: size.x,
      height: size.y,
    );

    final glow = Paint()..color = _glowColor.withValues(alpha: 0.28 * _blinkAlpha);
    final core = Paint()..color = _coreColor.withValues(alpha: _blinkAlpha);
    final shine = Paint()..color = _shineColor.withValues(alpha: _blinkAlpha);
    final border = Paint()
      ..color = _coreColor.withValues(alpha: 0.9 * _blinkAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(rect.inflate(size.x * 0.5), glow);
    canvas.drawRect(rect, core);
    canvas.drawRect(rect, border);

    final highlight = Rect.fromLTWH(
      rect.left + 1,
      rect.top + 1,
      rect.width * 0.45,
      rect.height * 0.45,
    );
    canvas.drawRect(highlight, shine);
  }
}
