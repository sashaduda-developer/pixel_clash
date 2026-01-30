import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/enemies/enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/orc_enemy.dart';

/// Фабрика орков (обычный/элитный).
class OrcEnemyFactory implements EnemyFactory {
  @override
  String get id => 'orc';

  @override
  EnemyComponent createNormal({
    required Vector2 position,
    required double speed,
    required int hp,
    required int damage,
    required int scoreReward,
    required int xpReward,
  }) {
    return OrcEnemyComponent(
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
    return OrcEliteEnemyComponent(
      position: position,
      speed: speed,
      hp: hp,
      damage: damage,
      scoreReward: scoreReward,
      xpReward: xpReward,
    );
  }
}
