import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Пробивающие снаряды: стрелы проходят сквозь несколько целей.
class PiercingProjectilesBuff extends LevelBasedBuff {
  PiercingProjectilesBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_piercing_projectiles');

  int get pierceCount {
    final v = levelValues();
    return altarInt(v, 'pierceCount', 0);
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
