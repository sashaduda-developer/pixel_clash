import 'dart:math';

import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Нова-взрыв: шанс взорвать область вокруг цели.
class NovaBurstBuff extends LevelBasedBuff {
  NovaBurstBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_nova_burst');

  double _cooldownLeft = 0;

  @override
  void onUpdate(PlayerComponent owner, double dt) {
    _cooldownLeft = max(0, _cooldownLeft - dt);
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! DamageDealtEvent) return;
    if (event.attacker != owner) return;
    if (event.target is! EnemyComponent) return;
    if (_cooldownLeft > 0) return;

    final v = levelValues();
    final procChance = altarNum(v, 'procChance', 0.10);
    if (owner.game.rng.nextDouble() > procChance) return;

    final internalCooldown = altarNum(v, 'internalCooldownSec', 1.0);
    final radius = altarRadius(altarNum(v, 'radius', 2.2));
    final damagePct = altarNum(v, 'damagePctOfHit', 0.70);

    final damage = max(1, (event.amount * damagePct).round());
    final center = (event.target as EnemyComponent).position;

    for (final e in enemiesInRadius(owner.game, center, radius)) {
      e.takeDamageFromHit(
        damage,
        isCrit: false,
        attacker: owner,
        sourceType: DamageSourceType.ability,
        showHitEffects: false,
      );
    }

    _cooldownLeft = internalCooldown;
  }
}
