import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';

/// ????????? ? ??????? ????.
class BruteEnemyComponent extends EnemyComponent {
  BruteEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
  });

  @override
  Color get baseColor => const Color(0xFF66BB6A);

  @override
  Color get flashColor => const Color(0xFFC8E6C9);

  @override
  Color get hpFillColor => const Color(0xFF2E7D32);

  @override
  double get bodySize => 36;

  @override
  double get hitboxRadius => 16;

  @override
  double get hpBarHeight => 5.0;
}

/// ??????? ?????? ???????.
class BruteEliteEnemyComponent extends BruteEnemyComponent {
  BruteEliteEnemyComponent({
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
  double get bodySize => 42;

  @override
  double get hitboxRadius => 19;

  @override
  double get hpBarHeight => 6.0;

  @override
  bool get drawEliteBorder => true;
}
