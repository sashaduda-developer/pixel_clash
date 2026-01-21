import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/ui/damage_number_component.dart';

/// Феникс-сердце: разово спасает от смерти и даёт 3 сек. неуязвимости.
class PhoenixHeartBuff extends Buff implements IncomingDamageModifier {
  PhoenixHeartBuff() : super(id: 'boss_phoenix_heart', rarity: Rarity.legendary);

  bool _used = false;
  double _invulnLeft = 0;

  @override
  bool get isStackable => false;

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}

  @override
  void onUpdate(PlayerComponent owner, double dt) {
    if (_invulnLeft > 0) {
      _invulnLeft = max(0, _invulnLeft - dt);
    }
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
    if (_used) return damage;

    final wouldDie = damage >= owner.stats.hp;
    if (!wouldDie) return damage;

    _used = true;
    _invulnLeft = 3.0;

    final reviveHp = max(1, (owner.stats.maxHp * 0.30).round());
    owner.stats.hp = reviveHp;
    owner.game.notifyPlayerStatsChanged();

    owner.game.worldMap.add(
      DamageNumberComponent(
        position: owner.position + Vector2(0, -24),
        value: 0,
        label: 'ФЕНИКС',
        color: const Color(0xFFFFD54F),
        scaleFactor: 1.1,
      ),
    );

    return 0;
  }
}
