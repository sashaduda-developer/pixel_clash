import 'dart:math';

import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Метка жнеца: после набора стаков вызывает взрыв.
class ReaperMarkBuff extends LevelBasedBuff {
  ReaperMarkBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_reaper_mark');

  int _stacks = 0;

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! EnemyKilledEvent) return;
    if (event.killer != owner) return;

    final v = levelValues();
    final stacksToExplode = max(1, altarInt(v, 'stacksToExplode', 10));
    _stacks += 1;

    if (_stacks < stacksToExplode) return;
    _stacks = 0;

    final radius = altarRadius(altarNum(v, 'radius', 3.2));
    final damagePct = altarNum(v, 'damagePctBase', 2.20);
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
  void onUpdate(PlayerComponent owner, double dt) {}
}
