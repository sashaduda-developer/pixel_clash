import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';

/// Фабрика для конкретного типа врага.
abstract class EnemyFactory {
  String get id;

  EnemyComponent createNormal({
    required Vector2 position,
    required double speed,
    required int hp,
    required int damage,
    required int scoreReward,
    required int xpReward,
  });

  EnemyComponent createElite({
    required Vector2 position,
    required double speed,
    required int hp,
    required int damage,
    required int scoreReward,
    required int xpReward,
  });
}
