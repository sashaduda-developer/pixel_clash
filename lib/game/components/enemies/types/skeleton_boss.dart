import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/enemies/animated_enemy_component.dart';

const AnimatedEnemyConfig _skeletonBossConfig = AnimatedEnemyConfig(
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
  spriteScale: 4.0,
  attackDelaySec: 0.16,
);

const AnimatedEnemyConfig _armoredSkeletonBossConfig = AnimatedEnemyConfig(
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
  spriteScale: 4.0,
  attackDelaySec: 0.18,
);

const AnimatedEnemyConfig _greatswordSkeletonBossConfig = AnimatedEnemyConfig(
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
  spriteScale: 4.0,
  attackDelaySec: 0.22,
);

/// Base skeleton boss (no abilities yet).
abstract class _SkeletonBossBase extends AnimatedEnemyComponent {
  _SkeletonBossBase({
    required super.config,
    required super.position,
    super.speed = 70,
    super.hp = 320,
    super.damage = 16,
    super.scoreReward = 55,
    super.xpReward = 40,
  });

  @override
  bool get isBoss => true;

  @override
  Color get baseColor => const Color(0xFF8E24AA);

  @override
  Color get flashColor => const Color(0xFFCE93D8);

  @override
  Color get hpFillColor => const Color(0xFFAB47BC);

  @override
  double get bodySize => 70;

  @override
  double get hitboxRadius => 32;

  @override
  double get hpBarHeight => 7.0;

  @override
  bool get drawEliteBorder => true;

  @override
  Color get eliteBorderColor => const Color(0x88FFFFFF);
}

class SkeletonBossComponent extends _SkeletonBossBase {
  SkeletonBossComponent({
    required super.position,
    super.speed = 70,
    super.hp = 320,
    super.damage = 16,
    super.scoreReward = 55,
    super.xpReward = 40,
  }) : super(config: _skeletonBossConfig);

  @override
  String get bossName => game.l10n.t('boss_skeleton_king');
}

class ArmoredSkeletonBossComponent extends _SkeletonBossBase {
  ArmoredSkeletonBossComponent({
    required super.position,
    super.speed = 68,
    super.hp = 340,
    super.damage = 17,
    super.scoreReward = 60,
    super.xpReward = 42,
  }) : super(config: _armoredSkeletonBossConfig);

  @override
  String get bossName => game.l10n.t('boss_armored_skeleton_king');
}

class GreatswordSkeletonBossComponent extends _SkeletonBossBase {
  GreatswordSkeletonBossComponent({
    required super.position,
    super.speed = 66,
    super.hp = 350,
    super.damage = 18,
    super.scoreReward = 65,
    super.xpReward = 45,
  }) : super(config: _greatswordSkeletonBossConfig);

  @override
  String get bossName => game.l10n.t('boss_greatsword_skeleton_king');
}
