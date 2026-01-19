import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/ui/damage_number_component.dart';

/// Вампиризм (магия алтаря):
/// - срабатывает на КАЖДЫЙ успешный удар по врагу
/// - лечит на % от нанесённого урона
class VampirismBuff extends Buff {
  VampirismBuff({
    required super.rarity,
    required this.baseLifesteal,
  }) : super(id: 'buff_vampirism');

  /// 0.05 = 5%
  final double baseLifesteal;

  /// Можно масштабировать от уровня стака (если понадобится).
  double get lifesteal => min(0.35, baseLifesteal * max(1, level));

  @override
  void onEvent(owner, CombatEvent event) {
    if (event is! DamageDealtEvent) return;

    // Только урон, нанесённый владельцем бафа (игроком)
    if (event.attacker != owner) return;

    // Только по врагам
    if (event.target is! EnemyComponent) return;

    // Лечим на каждый удар
    final heal = (event.amount * lifesteal).round();
    if (heal <= 0) return;

    owner.stats.heal(heal);
    owner.game.notifyPlayerStatsChanged();

    // Маленькие зелёные цифры лечения над игроком (приятный фидбек)
    owner.game.worldMap.add(
      DamageNumberComponent(
        position: owner.position + Vector2(0, -24),
        value: heal,
        color: const Color(0xFF66FF99),
      ),
    );
  }
}
