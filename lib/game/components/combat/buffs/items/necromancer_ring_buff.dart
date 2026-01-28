import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/ui/damage_number_component.dart';

class NecromancerRingBuff extends Buff {
  NecromancerRingBuff({
    required super.rarity,
    required this.baseLifesteal,
  }) : super(id: 'item_necromancer_ring');

  final double baseLifesteal;

  double get lifesteal => min(0.45, baseLifesteal * max(1, level));

  @override
  void onEvent(owner, CombatEvent event) {
    if (event is! DamageDealtEvent) return;
    if (event.attacker != owner) return;
    if (event.target is! EnemyComponent) return;

    final heal = (event.amount * lifesteal).round();
    if (heal <= 0) return;

    owner.stats.heal(heal);
    owner.game.notifyPlayerStatsChanged();

    owner.game.worldMap.add(
      DamageNumberComponent(
        position: owner.position + Vector2(0, -24),
        value: heal,
        color: const Color(0xFF66FF99),
      ),
    );
  }
}
