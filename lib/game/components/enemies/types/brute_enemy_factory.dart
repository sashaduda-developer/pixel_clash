import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/enemies/enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/brute_enemy.dart';

/// ??????? ?????? (???????, ?????????, ??????? ????).
class BruteEnemyFactory implements EnemyFactory {
  @override
  String get id => 'brute';

  @override
  EnemyComponent createNormal({
    required Vector2 position,
    required double speed,
    required int hp,
    required int damage,
    required int scoreReward,
    required int xpReward,
  }) {
    return BruteEnemyComponent(
      position: position,
      speed: speed * 0.85,
      hp: (hp * 1.55).round().clamp(1, 999999),
      damage: (damage * 1.30).round().clamp(1, 999999),
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
    return BruteEliteEnemyComponent(
      position: position,
      speed: speed * 0.80,
      hp: (hp * 1.85).round().clamp(1, 999999),
      damage: (damage * 1.45).round().clamp(1, 999999),
      scoreReward: scoreReward,
      xpReward: xpReward,
    );
  }
}
