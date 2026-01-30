import 'dart:math';

import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

class MessengerHeartBuff extends Buff {
  MessengerHeartBuff({
    required super.rarity,
    required this.speedPct,
    required this.durationSec,
  }) : super(id: 'item_heart_messenger');

  final double speedPct;
  final double durationSec;

  double _timeLeft = 0;
  double _appliedMultiplier = 1.0;

  @override
  bool get isStackable => false;

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! LootCollectedEvent) return;
    _trigger(owner);
  }

  @override
  void onUpdate(PlayerComponent owner, double dt) {
    if (_timeLeft <= 0) return;
    _timeLeft = max(0, _timeLeft - dt);
    if (_timeLeft > 0) return;

    if (_appliedMultiplier != 1.0) {
      owner.stats.moveSpeed /= _appliedMultiplier;
      _appliedMultiplier = 1.0;
      owner.game.notifyPlayerStatsChanged();
    }
  }

  void _trigger(PlayerComponent owner) {
    final duration = max(0.0, durationSec);
    if (duration <= 0) return;

    if (_timeLeft > 0) {
      _timeLeft = duration;
      return;
    }

    final mult = (1.0 + speedPct).clamp(1.0, 3.0);
    _appliedMultiplier = mult;
    owner.stats.moveSpeed *= mult;
    _timeLeft = duration;
    owner.game.notifyPlayerStatsChanged();
  }
}
