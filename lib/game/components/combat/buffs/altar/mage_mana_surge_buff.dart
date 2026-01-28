import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Сгусток маны: усиливает урон огня, но увеличивает расход маны за выстрел.
class MageManaSurgeBuff extends LevelBasedBuff {
  MageManaSurgeBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_mage_mana_surge');

  double get damageMultiplier {
    final v = levelValues();
    return altarNum(v, 'damageMultiplier', 1.0);
  }

  double get manaCost {
    final v = levelValues();
    return altarNum(v, 'manaCost', 0.0);
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
