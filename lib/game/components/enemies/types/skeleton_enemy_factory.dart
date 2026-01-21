import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/enemies/enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/skeleton_enemy.dart';

/// Фабрика скелетов (обычный/элитный).
class SkeletonEnemyFactory implements EnemyFactory {
  @override
  String get id => 'skeleton';

  @override
  EnemyComponent createNormal({
    required Vector2 position,
    required double speed,
    required int hp,
    required int damage,
    required int scoreReward,
    required int xpReward,
  }) {
    return SkeletonEnemyComponent(
      position: position,
      speed: speed,
      hp: hp,
      damage: damage,
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
    return SkeletonEliteEnemyComponent(
      position: position,
      speed: speed,
      hp: hp,
      damage: damage,
      scoreReward: scoreReward,
      xpReward: xpReward,
    );
  }
}
