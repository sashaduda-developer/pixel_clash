import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/ui/damage_number_component.dart';

/// Кристалл времени: раз в 25 сек лечит урон, полученный за 2 сек.
class TimeCrystalBuff extends Buff {
  TimeCrystalBuff() : super(id: 'boss_time_crystal', rarity: Rarity.legendary);

  double _cooldownLeft = 0;
  final List<_RecentDamage> _recent = <_RecentDamage>[];

  @override
  bool get isStackable => false;

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! DamageTakenEvent) return;
    if (event.victim != owner) return;
    if (event.amount <= 0) return;

    _recent.add(
      _RecentDamage(amount: event.amount, timeLeft: 2.0),
    );
  }

  @override
  void onUpdate(PlayerComponent owner, double dt) {
    _cooldownLeft = max(0, _cooldownLeft - dt);

    for (final r in List<_RecentDamage>.from(_recent)) {
      r.timeLeft -= dt;
      if (r.timeLeft <= 0) {
        _recent.remove(r);
      }
    }

    if (_cooldownLeft > 0) return;
    if (_recent.isEmpty) return;

    final heal = _recent.fold<int>(0, (sum, r) => sum + r.amount);
    if (heal <= 0) return;

    owner.stats.heal(heal);
    owner.game.notifyPlayerStatsChanged();

    owner.game.worldMap.add(
      DamageNumberComponent(
        position: owner.position + Vector2(0, -24),
        value: heal,
        color: const Color(0xFF4FC3F7),
      ),
    );

    _recent.clear();
    _cooldownLeft = 25.0;
  }
}

class _RecentDamage {
  _RecentDamage({
    required this.amount,
    required this.timeLeft,
  });

  final int amount;
  double timeLeft;
}
