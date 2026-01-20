import 'dart:math';

import 'package:pixel_clash/game/components/combat/active_ability.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Замедление времени: активная способность, замедляющая врагов вокруг.
class TimeDilationAbility extends LevelBasedBuff implements ActiveAbility {
  TimeDilationAbility({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'ability_time_dilation');

  double _cooldownLeft = 0;
  double _cooldownDuration = 0;

  @override
  double get cooldownLeft => _cooldownLeft;

  @override
  double get cooldownDuration => _cooldownDuration > 0 ? _cooldownDuration : _cooldownSec();

  @override
  double get manaCost => 26.0;

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

    final radius = altarRadius(altarNum(v, 'radius', 5.0));
    final slowPct = altarNum(v, 'slowPct', 0.45);
    final durationSec = altarNum(v, 'durationSec', 2.0);

    for (final e in enemiesInRadius(owner.game, owner.position, radius)) {
      e.applySlow(slowPct, durationSec);
    }

    _cooldownDuration = cooldownSec;
    _cooldownLeft = cooldownSec;
    return true;
  }

  double _cooldownSec() {
    final v = levelValues();
    return altarNum(v, 'cooldownSec', 24.0);
  }
}
