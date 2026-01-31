import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/ui/damage_number_component.dart';

abstract class PotionComponent extends PositionComponent
    with HasGameReference<PixelClashGame> {
  PotionComponent({
    required super.position,
    this.pickupRadius = 36,
  });

  final double pickupRadius;

  double _bob = 0;
  bool _collected = false;

  Color get baseColor;
  Color get glowColor;
  Color get borderColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(20);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_collected) return;
    if (game.isRewardPauseActive) return;

    _bob += dt * 4.5;

    final p = game.player;
    if (p == null || p.isRemoving) return;

    final r2 = pickupRadius * pickupRadius;
    if (p.position.distanceToSquared(position) <= r2) {
      _collected = true;
      onPickup(p);
      removeFromParent();
    }
  }

  void onPickup(PlayerComponent player);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bob = sin(_bob) * 1.2;
    final center = Offset(size.x / 2, size.y / 2 + bob);
    final r = size.x / 2;

    final glow = Paint()..color = glowColor.withValues(alpha: 0.35);
    final fill = Paint()..color = baseColor;
    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, r * 1.4, glow);
    canvas.drawCircle(center, r, fill);
    canvas.drawCircle(center, r, border);

    // small cap
    final capRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - r - 3),
      width: r * 0.8,
      height: r * 0.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(2)),
      border,
    );
  }
}

class HealPotionComponent extends PotionComponent {
  HealPotionComponent({
    required super.position,
    super.pickupRadius,
    this.healPct = 0.30,
    this.minHeal = 6,
  });

  final double healPct;
  final int minHeal;

  @override
  Color get baseColor => const Color(0xFF66BB6A);

  @override
  Color get glowColor => const Color(0xFF66BB6A);

  @override
  Color get borderColor => const Color(0xFF1B5E20);

  @override
  void onPickup(PlayerComponent player) {
    final heal = max(minHeal, (player.stats.maxHp * healPct).round());
    player.stats.heal(heal);
    game.notifyPlayerStatsChanged();
    game.worldMap.add(
      DamageNumberComponent(
        position: player.position + Vector2(0, -24),
        value: heal,
        color: const Color(0xFF66FF99),
      ),
    );
  }
}

class ShieldPotionComponent extends PotionComponent {
  ShieldPotionComponent({
    required super.position,
    super.pickupRadius,
    this.invulnSeconds = 3.0,
  });

  final double invulnSeconds;

  @override
  Color get baseColor => const Color(0xFF64B5F6);

  @override
  Color get glowColor => const Color(0xFF64B5F6);

  @override
  Color get borderColor => const Color(0xFF1E88E5);

  @override
  void onPickup(PlayerComponent player) {
    player.grantInvulnerability(invulnSeconds);
    game.worldMap.add(
      DamageNumberComponent(
        position: player.position + Vector2(0, -24),
        value: 0,
        label: game.l10n.t('combat_shield'),
        color: const Color(0xFF90CAF9),
      ),
    );
  }
}
