import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/enemies/enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/skeleton_enemies.dart';

class ArmoredSkeletonEnemyFactory implements EnemyFactory {
  @override
  String get id => 'armored_skeleton';

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
    return ArmoredSkeletonEnemyComponent(
      position: position,
      speed: speed * 0.85,
      hp: _scaleInt(hp, 1.6),
      damage: _scaleInt(damage, 1.25),
      scoreReward: _scaleInt(scoreReward, 1.35),
      xpReward: _scaleInt(xpReward, 1.25),
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
    return ArmoredSkeletonEliteEnemyComponent(
      position: position,
      speed: speed * 0.85,
      hp: _scaleInt(hp, 1.6),
      damage: _scaleInt(damage, 1.25),
      scoreReward: _scaleInt(scoreReward, 1.35),
      xpReward: _scaleInt(xpReward, 1.25),
    );
  }
}
