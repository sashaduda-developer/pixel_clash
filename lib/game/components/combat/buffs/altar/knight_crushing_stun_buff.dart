import 'dart:math';

import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Сокрушение: каждый X-й удар оглушает цель.
class KnightCrushingStunBuff extends LevelBasedBuff {
  KnightCrushingStunBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_knight_crushing_stun');

  int _hitCounter = 0;

  int get hitsToStun {
    final v = levelValues();
    return max(1, altarInt(v, 'hitsToStun', 5));
  }

  double get stunSec {
    final v = levelValues();
    return altarNum(v, 'stunSec', 0.6);
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! DamageDealtEvent) return;
    if (event.attacker != owner) return;
    if (event.sourceType != DamageSourceType.melee) return;
    if (event.target is! EnemyComponent) return;

    _hitCounter += 1;
    if (_hitCounter < hitsToStun) return;
    _hitCounter = 0;

    final target = event.target as EnemyComponent;
    target.applyStun(stunSec);
  }

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
