import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Уклонение-удар: усиливает крит после успешного уворота.
class NinjaEvasionStrikeBuff extends LevelBasedBuff {
  NinjaEvasionStrikeBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_ninja_evasion_strike');

  double get critBonusMultiplier {
    final v = levelValues();
    return altarNum(v, 'critBonusMultiplier', 0.0);
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
