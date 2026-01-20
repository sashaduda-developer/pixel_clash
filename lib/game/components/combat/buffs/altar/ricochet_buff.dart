import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Рикошет: снаряд после попадания прыгает в другую цель.
class RicochetBuff extends LevelBasedBuff {
  RicochetBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_ricochet');

  int get bounces {
    final v = levelValues();
    return altarInt(v, 'bounces', 0);
  }

  double get damageMultiplier {
    final v = levelValues();
    return altarNum(v, 'damageMultiplier', 0.7);
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
