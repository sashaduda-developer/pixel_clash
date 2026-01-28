import 'dart:math';
import 'dart:ui';

import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/ui/hit_particles.dart';

/// Огненная сфера: при попадании огненным снарядом наносит AoE вокруг цели.
class MageFireSphereBuff extends LevelBasedBuff {
  MageFireSphereBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_mage_fire_sphere');

  double get radius {
    final v = levelValues();
    return altarRadius(altarNum(v, 'radius', 1.8));
  }

  double get damagePctOfHit {
    final v = levelValues();
    return altarNum(v, 'damagePctOfHit', 0.35);
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! DamageDealtEvent) return;
    if (event.sourceType != DamageSourceType.ability) return;
    if (event.target is! EnemyComponent) return;

    final hit = event.target as EnemyComponent;
    final center = hit.position;

    for (final e in enemiesInRadius(owner.game, center, radius)) {
      if (e == hit) continue;
      final extra = max(1, (event.amount * damagePctOfHit).round());
      e.takeDamageFromHit(
        extra,
        isCrit: false,
        attacker: owner,
        sourceType: DamageSourceType.ability,
        showHitEffects: false,
      );
    }

    // Легкая вспышка, чтобы было видно AoE.
    spawnHitParticles(
      parent: owner.game.worldMap,
      position: center,
      color: const Color(0xFFFF8A50),
      count: 10,
    );
  }

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
