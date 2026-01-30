import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/enemies/animated_enemy_component.dart';

const AnimatedEnemyConfig _skeletonConfig = AnimatedEnemyConfig(
  basePath: 'enemies/Skeleton/',
  idleFile: 'Skeleton-Idle.png',
  walkFile: 'Skeleton-Walk.png',
  attackFile: 'Skeleton-Attack.png',
  hurtFile: 'Skeleton-Hurt.png',
  deathFile: 'Skeleton-Death.png',
  idleFrames: 6,
  walkFrames: 8,
  attackFrames: 6,
  hurtFrames: 4,
  deathFrames: 4,
  attackStepTime: 0.07,
);

const AnimatedEnemyConfig _skeletonEliteConfig = AnimatedEnemyConfig(
  basePath: 'enemies/Skeleton-Elite/',
  idleFile: 'Skeleton-Elite-Idle.png',
  walkFile: 'Skeleton-Elite-Walk.png',
  attackFile: 'Skeleton-Elite-Attack.png',
  hurtFile: 'Skeleton-Elite-Hurt.png',
  deathFile: 'Skeleton-Elite-Death.png',
  idleFrames: 6,
  walkFrames: 8,
  attackFrames: 6,
  hurtFrames: 4,
  deathFrames: 4,
  attackStepTime: 0.07,
);

const AnimatedEnemyConfig _armoredSkeletonConfig = AnimatedEnemyConfig(
  basePath: 'enemies/Armored-Skeleton/',
  idleFile: 'Armored Skeleton-Idle.png',
  walkFile: 'Armored Skeleton-Walk.png',
  attackFile: 'Armored Skeleton-Attack.png',
  hurtFile: 'Armored Skeleton-Hurt.png',
  deathFile: 'Armored Skeleton-Death.png',
  idleFrames: 6,
  walkFrames: 8,
  attackFrames: 8,
  hurtFrames: 4,
  deathFrames: 4,
  attackStepTime: 0.08,
  attackDelaySec: 0.16,
);

const AnimatedEnemyConfig _armoredSkeletonEliteConfig = AnimatedEnemyConfig(
  basePath: 'enemies/Armored-Skeleton-Elite/',
  idleFile: 'Armored-Skeleton-Elite-Idle.png',
  walkFile: 'Armored-Skeleton-Elite-Walk.png',
  attackFile: 'Armored-Skeleton-Elite-Attack.png',
  hurtFile: 'Armored-Skeleton-Elite-Hurt.png',
  deathFile: 'Armored-Skeleton-Elite-Death.png',
  idleFrames: 6,
  walkFrames: 8,
  attackFrames: 8,
  hurtFrames: 4,
  deathFrames: 4,
  attackStepTime: 0.08,
  attackDelaySec: 0.16,
);

const AnimatedEnemyConfig _greatswordSkeletonConfig = AnimatedEnemyConfig(
  basePath: 'enemies/Greatsword-Skeleton/',
  idleFile: 'Greatsword Skeleton-Idle.png',
  walkFile: 'Greatsword Skeleton-Walk.png',
  attackFile: 'Greatsword Skeleton-Attack.png',
  hurtFile: 'Greatsword Skeleton-Hurt.png',
  deathFile: 'Greatsword Skeleton-Death.png',
  idleFrames: 6,
  walkFrames: 9,
  attackFrames: 8,
  hurtFrames: 4,
  deathFrames: 4,
  attackStepTime: 0.09,
  attackDelaySec: 0.22,
);

const AnimatedEnemyConfig _greatswordSkeletonEliteConfig = AnimatedEnemyConfig(
  basePath: 'enemies/Greatsword-Skeleton-Elite/',
  idleFile: 'Greatsword-Skeleton-Elite-Idle.png',
  walkFile: 'Greatsword-Skeleton-Elite-Walk.png',
  attackFile: 'Greatsword-Skeleton-Elite-Attack.png',
  hurtFile: 'Greatsword-Skeleton-Elite-Hurt.png',
  deathFile: 'Greatsword-Skeleton-Elite-Death.png',
  idleFrames: 6,
  walkFrames: 9,
  attackFrames: 8,
  hurtFrames: 4,
  deathFrames: 4,
  attackStepTime: 0.09,
  attackDelaySec: 0.22,
);

class SkeletonEnemyComponent extends AnimatedEnemyComponent {
  SkeletonEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
  }) : super(config: _skeletonConfig);

  @override
  Color get baseColor => const Color(0xFFB0B0B0);

  @override
  Color get flashColor => const Color(0xFFF0F0F0);

  @override
  Color get hpFillColor => const Color(0xFF9E9E9E);

  @override
  double get bodySize => 30;

  @override
  double get hitboxRadius => 13;
}

class SkeletonEliteEnemyComponent extends AnimatedEnemyComponent {
  SkeletonEliteEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
  }) : super(config: _skeletonEliteConfig);

  @override
  Color get baseColor => const Color(0xFFFFD54F);

  @override
  Color get flashColor => const Color(0xFFFFF3C4);

  @override
  Color get hpFillColor => const Color(0xFFFFA000);

  @override
  double get bodySize => 32;

  @override
  double get hitboxRadius => 14;

  @override
  double get hpBarHeight => 5.0;

  @override
  bool get drawEliteBorder => true;

  @override
  Color get eliteBorderColor => const Color(0xAAFFD54F);
}

class ArmoredSkeletonEnemyComponent extends AnimatedEnemyComponent {
  ArmoredSkeletonEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
    AnimatedEnemyConfig config = _armoredSkeletonConfig,
  }) : super(config: config);

  @override
  Color get baseColor => const Color(0xFF9E9E9E);

  @override
  Color get flashColor => const Color(0xFFE0E0E0);

  @override
  Color get hpFillColor => const Color(0xFF757575);

  @override
  double get bodySize => 32;

  @override
  double get hitboxRadius => 14;
}

class ArmoredSkeletonEliteEnemyComponent extends ArmoredSkeletonEnemyComponent {
  ArmoredSkeletonEliteEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
  }) : super(config: _armoredSkeletonEliteConfig);

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

  @override
  Color get eliteBorderColor => const Color(0xAAFFD54F);
}

class GreatswordSkeletonEnemyComponent extends AnimatedEnemyComponent {
  GreatswordSkeletonEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
    AnimatedEnemyConfig config = _greatswordSkeletonConfig,
  }) : super(config: config);

  @override
  Color get baseColor => const Color(0xFF8D8D8D);

  @override
  Color get flashColor => const Color(0xFFE0E0E0);

  @override
  Color get hpFillColor => const Color(0xFF6D6D6D);

  @override
  double get bodySize => 34;

  @override
  double get hitboxRadius => 15;
}

class GreatswordSkeletonEliteEnemyComponent extends GreatswordSkeletonEnemyComponent {
  GreatswordSkeletonEliteEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
  }) : super(config: _greatswordSkeletonEliteConfig);

  @override
  Color get baseColor => const Color(0xFFFFD54F);

  @override
  Color get flashColor => const Color(0xFFFFF3C4);

  @override
  Color get hpFillColor => const Color(0xFFFFA000);

  @override
  double get bodySize => 36;

  @override
  double get hitboxRadius => 16;

  @override
  double get hpBarHeight => 5.0;

  @override
  bool get drawEliteBorder => true;

  @override
  Color get eliteBorderColor => const Color(0xAAFFD54F);
}
