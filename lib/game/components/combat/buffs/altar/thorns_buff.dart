import 'dart:math';

import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Шипы: отражает часть полученного урона обратно во врага.
class ThornsBuff extends LevelBasedBuff {
  ThornsBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_thorns');

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! DamageTakenEvent) return;
    if (event.victim != owner) return;

    final attacker = event.attacker;
    if (attacker is! EnemyComponent) return;

    final v = levelValues();
    final reflectPct = altarNum(v, 'reflectPct', 0.12);
    final reflectDamage = max(1, (event.amount * reflectPct).round());

    attacker.takeDamageFromHit(
      reflectDamage,
      isCrit: false,
      attacker: owner,
      sourceType: DamageSourceType.thorn,
      showHitEffects: false,
    );
  }

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
