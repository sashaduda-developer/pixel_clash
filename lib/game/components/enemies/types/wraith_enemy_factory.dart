import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/enemies/enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/wraith_enemy.dart';

/// ??????? ????????? (???????, ???????, ?????????? ????).
class WraithEnemyFactory implements EnemyFactory {
  @override
  String get id => 'wraith';

  @override
  EnemyComponent createNormal({
    required Vector2 position,
    required double speed,
    required int hp,
    required int damage,
    required int scoreReward,
    required int xpReward,
  }) {
    return WraithEnemyComponent(
      position: position,
      speed: speed * 1.15,
      hp: (hp * 0.85).round().clamp(1, 999999),
      damage: (damage * 1.15).round().clamp(1, 999999),
      scoreReward: scoreReward,
      xpReward: xpReward,
    );
  }

  @override
  EnemyComponent createElite({
    required Vector2 position,
    required double speed,
    required int hp,
    required int damage,
    required int scoreReward,
    required int xpReward,
  }) {
    return WraithEliteEnemyComponent(
      position: position,
      speed: speed * 1.20,
      hp: (hp * 0.95).round().clamp(1, 999999),
      damage: (damage * 1.25).round().clamp(1, 999999),
      scoreReward: scoreReward,
      xpReward: xpReward,
    );
  }
}
