import 'dart:math';

import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

class PainMirrorBuff extends Buff {
  PainMirrorBuff({
    required super.rarity,
    required this.baseReflectPct,
  }) : super(id: 'item_pain_mirror');

  final double baseReflectPct;

  double get reflectPct => min(0.60, baseReflectPct * max(1, level));

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! DamageTakenEvent) return;
    if (event.victim != owner) return;

    final attacker = event.attacker;
    if (attacker is! EnemyComponent) return;

    final reflectDamage = max(1, (event.amount * reflectPct).round());
    attacker.takeDamageFromHit(
      reflectDamage,
      isCrit: false,
      attacker: owner,
      sourceType: DamageSourceType.thorn,
      showHitEffects: false,
    );
  }
}
