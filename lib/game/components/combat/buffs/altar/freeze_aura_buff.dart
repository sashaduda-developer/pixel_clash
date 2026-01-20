import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/altar_buff_utils.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar/level_based_buff.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Аура заморозки: периодически замораживает врагов рядом с игроком.
class FreezeAuraBuff extends LevelBasedBuff {
  FreezeAuraBuff({
    required super.rarity,
    required super.maxLevel,
    required super.levels,
  }) : super(id: 'buff_freeze_aura');

  double _timer = 0;

  @override
  void onUpdate(PlayerComponent owner, double dt) {
    final v = levelValues();
    final intervalSec = altarNum(v, 'intervalSec', 6.0);
    if (intervalSec <= 0) return;

    _timer += dt;
    if (_timer < intervalSec) return;
    _timer -= intervalSec;

    final radius = altarRadius(altarNum(v, 'radius', 1.7));
    final freezeSec = altarNum(v, 'freezeSec', 0.8);

    for (final e in enemiesInRadius(owner.game, owner.position, radius)) {
      e.applyFreeze(freezeSec);
    }
  }

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {}
}
