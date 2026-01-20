import 'dart:math';

import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/ui/crit_lightning_component.dart';

/// Перк: Цепная молния.
/// Теперь срабатывает НЕ по криту, а по шансу на каждый успешный удар игрока.
class ChainLightningBuff extends Buff {
  ChainLightningBuff({
    required super.rarity,
  }) : super(
          id: 'buff_chain_lightning',
        );

  int get _baseJumps => switch (rarity) {
        Rarity.common => 1,
        Rarity.rare => 2,
        Rarity.epic => 3,
        Rarity.legendary => 4,
      };

  int get jumps => _baseJumps + max(0, level - 1);

  double get radius => 180 + 10.0 * max(0, level - 1);

  /// Базовый шанс прока (на удар).
  double get _baseProcChance => switch (rarity) {
        Rarity.common => 0.08,
        Rarity.rare => 0.12,
        Rarity.epic => 0.18,
        Rarity.legendary => 0.25,
      };

  double get procChance => min(0.60, _baseProcChance + 0.03 * max(0, level - 1));

  /// Урон цепи от урона удара.
  double get damageMultiplier => min(0.60, 0.35 + 0.03 * max(0, level - 1));

  @override
  void onEvent(owner, CombatEvent event) {
    if (event is! DamageDealtEvent) return;

    // только атаки игрока
    if (event.attacker != owner) return;

    final first = event.target;
    if (first is! EnemyComponent) return;

    // прок по шансу
    final r = owner.game.rng.nextDouble();
    if (r > procChance) return;

    _jump(owner, firstTarget: first, baseDamage: event.amount);
  }

  void _jump(
    owner, {
    required EnemyComponent firstTarget,
    required int baseDamage,
  }) {
    final game = owner.game;

    final chainDamage = (baseDamage * damageMultiplier).round().clamp(1, 999999);

    final hit = <EnemyComponent>{firstTarget};
    var currentPos = firstTarget.position.clone();

    for (var i = 0; i < jumps; i++) {
      final next = game.findNearestEnemyInRadius(
        currentPos,
        radius,
        exclude: hit,
      );
      if (next == null) return;

      hit.add(next);

      game.worldMap.add(
        CritLightningComponent(position: next.position + Vector2(0, -10)),
      );

      // Урон цепью: без крита.
      next.takeDamageFromHit(
        chainDamage,
        isCrit: false,
        attacker: owner,
        sourceType: DamageSourceType.ability,
      );

      currentPos = next.position.clone();
    }
  }
}
