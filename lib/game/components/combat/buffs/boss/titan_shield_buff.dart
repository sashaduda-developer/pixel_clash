import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/ui/damage_number_component.dart';

/// Щит титана: первый удар раз в 12 сек полностью игнорируется.
class TitanShieldBuff extends Buff implements IncomingDamageModifier {
  TitanShieldBuff() : super(id: 'boss_titan_shield', rarity: Rarity.legendary);

  double _cooldownLeft = 0;

  @override
  bool get isStackable => false;

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}

  @override
  void onUpdate(PlayerComponent owner, double dt) {
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
    if (_cooldownLeft > 0) return damage;

    _cooldownLeft = 12.0;

    owner.game.worldMap.add(
      DamageNumberComponent(
        position: owner.position + Vector2(0, -24),
        value: 0,
        label: 'ЩИТ',
        color: const Color(0xFF90CAF9),
      ),
    );

    return 0;
  }
}
