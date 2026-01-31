import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/ui/damage_number_component.dart';

class VoidMaskBuff extends Buff implements IncomingDamageModifier {
  VoidMaskBuff({
    required super.rarity,
    required this.procChance,
    required this.durationSec,
    required this.cooldownSec,
  }) : super(id: 'item_mask_void');

  final double procChance;
  final double durationSec;
  final double cooldownSec;

  double _invulnLeft = 0;
  double _cooldownLeft = 0;

  @override
  bool get isStackable => false;

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}

  @override
  void onUpdate(PlayerComponent owner, double dt) {
    _invulnLeft = max(0, _invulnLeft - dt);
    _cooldownLeft = max(0, _cooldownLeft - dt);
  }

  @override
  int modifyIncomingDamage(
    PlayerComponent owner,
    int damage,
    DamageSourceType sourceType,
    PositionComponent? attacker,
  ) {
    if (damage <= 0) return 0;
    if (_invulnLeft > 0) return 0;
    if (_cooldownLeft > 0) return damage;

    final chance = procChance.clamp(0.0, 1.0);
    if (chance <= 0) return damage;
    if (owner.game.rng.nextDouble() > chance) return damage;

    _invulnLeft = max(0.0, durationSec);
    _cooldownLeft = max(0.0, cooldownSec);

    owner.game.worldMap.add(
      DamageNumberComponent(
        position: owner.position + Vector2(0, -24),
        value: 0,
        label: owner.game.l10n.t('combat_void'),
        color: const Color(0xFFB39DDB),
      ),
    );

    return 0;
  }
}
