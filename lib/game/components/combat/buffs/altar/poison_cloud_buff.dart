import 'dart:math';

import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Ядовитое облако: постоянная аура урона вокруг игрока.
class PoisonCloudBuff extends LevelBasedBuff {
  PoisonCloudBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_poison_cloud');

  double _tickLeft = 0;

  @override
  void onUpdate(PlayerComponent owner, double dt) {
    final v = levelValues();
    final tickSec = altarNum(v, 'tickSec', 0.6);
    if (tickSec <= 0) return;

    _tickLeft -= dt;
    if (_tickLeft > 0) return;

    _tickLeft = tickSec;

    final radius = altarRadius(altarNum(v, 'radius', 2.0));
    final damagePct = altarNum(v, 'damagePctBase', 0.14);
    final damage = max(1, (owner.stats.damage * damagePct).round());

    for (final e in enemiesInRadius(owner.game, owner.position, radius)) {
      e.takeDamageFromHit(
        damage,
        isCrit: false,
        attacker: owner,
        sourceType: DamageSourceType.ability,
        showHitEffects: false,
      );
    }
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}
}
