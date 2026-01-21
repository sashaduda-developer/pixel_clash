import 'dart:math';

import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/ui/crit_lightning_component.dart';

/// Сердце молний: каждый 5-й полученный удар бьёт молнией ближайших врагов.
class StormHeartBuff extends Buff {
  StormHeartBuff() : super(id: 'boss_storm_heart', rarity: Rarity.legendary);

  int _hitCount = 0;

  @override
  bool get isStackable => false;

  @override
  void onEvent(PlayerComponent owner, CombatEvent event) {
    if (event is! DamageTakenEvent) return;
    if (event.victim != owner) return;
    if (event.amount <= 0) return;

    _hitCount += 1;
    if (_hitCount < 5) return;
    _hitCount = 0;

    _triggerLightning(owner);
  }

  void _triggerLightning(PlayerComponent owner) {
    final targets = _nearestEnemies(owner, 3, 220);
    if (targets.isEmpty) return;

    final baseDamage = max(1, owner.stats.damage);
    final dmg = (baseDamage * 0.8).round().clamp(1, 999999);

    for (final e in targets) {
      e.takeDamageFromHit(
        dmg,
        isCrit: false,
        attacker: owner,
        sourceType: DamageSourceType.ability,
      );

      owner.game.worldMap.add(
        CritLightningComponent(
          position: e.position + Vector2(0, -10),
        ),
      );
    }
  }

  List<EnemyComponent> _nearestEnemies(PlayerComponent owner, int maxCount, double radius) {
    final enemies = <EnemyComponent>[];
    final r2 = radius * radius;

    for (final c in owner.game.worldMap.children) {
      if (c is! EnemyComponent) continue;
      if (c.isDead || c.isRemoving) continue;

      final d2 = c.position.distanceToSquared(owner.position);
      if (d2 > r2) continue;
      enemies.add(c);
    }

    enemies.sort((a, b) {
      final da = a.position.distanceToSquared(owner.position);
      final db = b.position.distanceToSquared(owner.position);
      return da.compareTo(db);
    });

    if (enemies.length > maxCount) {
      return enemies.sublist(0, maxCount);
    }
    return enemies;
  }
}
