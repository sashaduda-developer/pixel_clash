import 'dart:math';

import 'package:pixel_clash/game/components/combat/active_ability.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Ударная волна: активная способность с оглушением.
class ShockwaveStunAbility extends LevelBasedBuff implements ActiveAbility {
  ShockwaveStunAbility({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'ability_shockwave_stun');

  double _cooldownLeft = 0;
  double _cooldownDuration = 0;

  @override
  double get cooldownLeft => _cooldownLeft;

  @override
  double get cooldownDuration => _cooldownDuration > 0 ? _cooldownDuration : _cooldownSec();

  @override
  double get manaCost => 32.0;

  @override
  void onUpdate(PlayerComponent owner, double dt) {
    _cooldownLeft = max(0, _cooldownLeft - dt);
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}

  @override
  bool tryActivate(PlayerComponent owner) {
    if (_cooldownLeft > 0) return false;
    if (!owner.stats.spendMana(manaCost)) return false;

    final v = levelValues();
    final cooldownSec = _cooldownSec();

    final radius = altarRadius(altarNum(v, 'radius', 3.2));
    final stunSec = altarNum(v, 'stunSec', 1.2);
    final damagePct = altarNum(v, 'damagePctBase', 0.90);
    final damage = max(1, (owner.stats.damage * damagePct).round());

    for (final e in enemiesInRadius(owner.game, owner.position, radius)) {
      e.applyStun(stunSec);
      e.takeDamageFromHit(
        damage,
        isCrit: false,
        attacker: owner,
        sourceType: DamageSourceType.ability,
        showHitEffects: false,
      );
    }

    _cooldownDuration = cooldownSec;
    _cooldownLeft = cooldownSec;
    return true;
  }

  double _cooldownSec() {
    final v = levelValues();
    return altarNum(v, 'cooldownSec', 18.0);
  }
}
