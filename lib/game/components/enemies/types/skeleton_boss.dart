import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';

/// Базовый босс-скелет (пока без способностей).
class SkeletonBossComponent extends EnemyComponent {
  SkeletonBossComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
  });

  @override
  bool get isBoss => true;

  @override
  String get bossName => 'Король скелетов';

  @override
  Color get baseColor => const Color(0xFF8E24AA);

  @override
  Color get flashColor => const Color(0xFFCE93D8);

  @override
  Color get hpFillColor => const Color(0xFFAB47BC);

  @override
  double get bodySize => 64;

  @override
  double get hitboxRadius => 30;

  @override
  double get hpBarHeight => 7.0;

  @override
  bool get drawEliteBorder => true;

  @override
  Color get eliteBorderColor => const Color(0x88FFFFFF);
}
