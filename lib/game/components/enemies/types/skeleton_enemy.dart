import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';

/// Базовый скелет.
class SkeletonEnemyComponent extends EnemyComponent {
  SkeletonEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
  });

  @override
  Color get baseColor => const Color(0xFFE0E0E0);

  @override
  Color get flashColor => const Color(0xFFFFFFFF);

  @override
  Color get hpFillColor => const Color(0xFFB71C1C);
}

/// Элитный скелет.
class SkeletonEliteEnemyComponent extends SkeletonEnemyComponent {
  SkeletonEliteEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
  });

  @override
  Color get baseColor => const Color(0xFFFFD54F);

  @override
  Color get flashColor => const Color(0xFFFFF3C4);

  @override
  Color get hpFillColor => const Color(0xFFFFA000);

  @override
  double get bodySize => 34;

  @override
  double get hitboxRadius => 15;

  @override
  double get hpBarHeight => 5.0;

  @override
  bool get drawEliteBorder => true;
}
