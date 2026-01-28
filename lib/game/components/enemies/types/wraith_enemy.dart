import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';

/// ??????? ? ??????? ????.
class WraithEnemyComponent extends EnemyComponent {
  WraithEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
  });

  @override
  Color get baseColor => const Color(0xFF7E57C2);

  @override
  Color get flashColor => const Color(0xFFD1C4E9);

  @override
  Color get hpFillColor => const Color(0xFF5E35B1);

  @override
  double get bodySize => 26;

  @override
  double get hitboxRadius => 11;
}

/// ??????? ?????? ????????.
class WraithEliteEnemyComponent extends WraithEnemyComponent {
  WraithEliteEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
  });

  @override
  Color get baseColor => const Color(0xFFFFB74D);

  @override
  Color get flashColor => const Color(0xFFFFE0B2);

  @override
  Color get hpFillColor => const Color(0xFFF57C00);

  @override
  double get bodySize => 30;

  @override
  double get hitboxRadius => 13;

  @override
  double get hpBarHeight => 5.0;

  @override
  bool get drawEliteBorder => true;
}
