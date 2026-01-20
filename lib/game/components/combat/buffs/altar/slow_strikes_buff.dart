import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Ледяные удары: каждый удар замедляет цель.
class SlowStrikesBuff extends LevelBasedBuff {
  SlowStrikesBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_slow_strikes');

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! DamageDealtEvent) return;
    if (event.attacker != owner) return;
    if (event.target is! EnemyComponent) return;

    final v = levelValues();
    final slowPct = altarNum(v, 'slowPct', 0.20);
    final durationSec = altarNum(v, 'durationSec', 0.7);

    final target = event.target as EnemyComponent;
    target.applySlow(slowPct, durationSec);
  }

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
