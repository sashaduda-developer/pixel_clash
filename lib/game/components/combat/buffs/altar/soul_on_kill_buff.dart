import 'dart:math';

import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Душа на убийство: шанс подлечиться при убийстве врага.
class SoulOnKillBuff extends LevelBasedBuff {
  SoulOnKillBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_soul_on_kill');

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! EnemyKilledEvent) return;
    if (event.killer != owner) return;

    final v = levelValues();
    final procChance = altarNum(v, 'procChance', 0.30);
    if (owner.game.rng.nextDouble() > procChance) return;

    final healPctMaxHp = altarNum(v, 'healPctMaxHp', 0.015);
    final heal = max(1, (owner.stats.maxHp * healPctMaxHp).round());

    owner.stats.heal(heal);
    owner.game.notifyPlayerStatsChanged();
  }

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
