import 'dart:math';

import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Поле бури: периодически поражает несколько целей вокруг игрока.
class TempestFieldBuff extends LevelBasedBuff {
  TempestFieldBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_tempest_field');

  double _timer = 0;

  @override
  void onUpdate(PlayerComponent owner, double dt) {
    final v = levelValues();
    final intervalSec = altarNum(v, 'intervalSec', 2.2);
    if (intervalSec <= 0) return;

    _timer += dt;
    if (_timer < intervalSec) return;
    _timer -= intervalSec;

    final targets = altarInt(v, 'targets', 2);
    final radius = altarRadius(altarNum(v, 'radius', 3.0));
    final damagePct = altarNum(v, 'damagePctBase', 0.85);
    final damage = max(1, (owner.stats.damage * damagePct).round());

    final enemies = nearestEnemies(owner.game, owner.position, radius, targets);
    for (final e in enemies) {
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
