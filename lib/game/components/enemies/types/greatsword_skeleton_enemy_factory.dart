import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/enemies/enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/skeleton_enemies.dart';

class GreatswordSkeletonEnemyFactory implements EnemyFactory {
  @override
  String get id => 'greatsword_skeleton';

  static int _scaleInt(int value, double mult) {
    return (value * mult).round().clamp(1, 999999);
  }

  @override
  EnemyComponent createNormal({
    required Vector2 position,
    required double speed,
    required int hp,
    required int damage,
    required int scoreReward,
    required int xpReward,
  }) {
    return GreatswordSkeletonEnemyComponent(
      position: position,
      speed: speed * 0.75,
      hp: _scaleInt(hp, 2.0),
      damage: _scaleInt(damage, 1.6),
      scoreReward: _scaleInt(scoreReward, 1.6),
      xpReward: _scaleInt(xpReward, 1.5),
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
    return GreatswordSkeletonEliteEnemyComponent(
      position: position,
      speed: speed * 0.75,
      hp: _scaleInt(hp, 2.0),
      damage: _scaleInt(damage, 1.6),
      scoreReward: _scaleInt(scoreReward, 1.6),
      xpReward: _scaleInt(xpReward, 1.5),
    );
  }
}
