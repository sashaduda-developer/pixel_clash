import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// РЈРєР»РѕРЅРµРЅРёРµ-СѓРґР°СЂ: СѓСЃРёР»РёРІР°РµС‚ РєСЂРёС‚ РїРѕСЃР»Рµ СѓСЃРїРµС€РЅРѕРіРѕ СѓРІРѕСЂРѕС‚Р°.
class SamuraiEvasionStrikeBuff extends LevelBasedBuff {
  SamuraiEvasionStrikeBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_samurai_evasion_strike');

  double get critBonusMultiplier {
    final v = levelValues();
    return altarNum(v, 'critBonusMultiplier', 0.0);
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
