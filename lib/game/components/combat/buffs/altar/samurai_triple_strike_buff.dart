import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// РўСЂРѕР№РЅРѕР№ СѓРґР°СЂ: С€Р°РЅСЃ Рё СѓСЂРѕРЅ С‚СЂРµС‚СЊРµРіРѕ СѓРґР°СЂР°.
class SamuraiTripleStrikeBuff extends LevelBasedBuff {
  SamuraiTripleStrikeBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_samurai_triple_strike');

  double get thirdHitChance {
    final v = levelValues();
    return altarNum(v, 'thirdHitChance', 0.0);
  }

  double get thirdHitDamageMultiplier {
    final v = levelValues();
    return altarNum(v, 'thirdHitDamageMultiplier', 0.8);
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
