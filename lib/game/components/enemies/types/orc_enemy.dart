import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/enemies/animated_enemy_component.dart';

const AnimatedEnemyConfig _orcConfig = AnimatedEnemyConfig(
  basePath: 'characters/Orc/Orc/',
  idleFile: 'Orc-Idle.png',
  walkFile: 'Orc-Walk.png',
  attackFile: 'Orc-Attack01.png',
  hurtFile: 'Orc-Hurt.png',
  deathFile: 'Orc-Death.png',
  idleFrames: 6,
  walkFrames: 8,
  attackFrames: 6,
  hurtFrames: 4,
  deathFrames: 4,
  idleStepTime: 0.14,
  walkStepTime: 0.10,
  attackStepTime: 0.07,
  hurtStepTime: 0.07,
  deathStepTime: 0.10,
  attackDelaySec: 0.14,
  spriteScale: 1.6,
);

/// Р‘Р°Р·РѕРІС‹Р№ РѕСЂРє.
class OrcEnemyComponent extends AnimatedEnemyComponent {
  OrcEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
  }) : super(config: _orcConfig);

  @override
  Color get baseColor => const Color(0xFF66BB6A);

  @override
  Color get flashColor => const Color(0xFFC8E6C9);

  @override
  Color get hpFillColor => const Color(0xFF2E7D32);

  @override
  double get bodySize => 30;

  @override
  double get hitboxRadius => 13;

  @override
  double get hpBarHeight => 4.0;
}

/// Р­Р»РёС‚РЅС‹Р№ РѕСЂРє.
class OrcEliteEnemyComponent extends OrcEnemyComponent {
  OrcEliteEnemyComponent({
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
  double get bodySize => 34;

  @override
  double get hitboxRadius => 15;

  @override
  double get hpBarHeight => 5.0;

  @override
  bool get drawEliteBorder => true;
}
