import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Кровотечение: шанс на урон по времени.
class BleedOnHitBuff extends LevelBasedBuff {
  BleedOnHitBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_bleed_on_hit');

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! DamageDealtEvent) return;
    if (event.attacker != owner) return;
    if (event.target is! EnemyComponent) return;

    final v = levelValues();
    final procChance = altarNum(v, 'procChance', 0.15);
    if (owner.game.rng.nextDouble() > procChance) return;

    final durationSec = altarNum(v, 'durationSec', 3.0);
    final totalDamagePct = altarNum(v, 'totalDamagePct', 0.30);

    final target = event.target as EnemyComponent;
    target.applyDot(
      id: 'bleed',
      baseDamage: event.amount,
      totalDamagePct: totalDamagePct,
      durationSec: durationSec,
      tickSec: 0.5,
      attacker: owner,
    );
  }

  @override
  void onUpdate(PlayerComponent owner, double dt) {}
}
