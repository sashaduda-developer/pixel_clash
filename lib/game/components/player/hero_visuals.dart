import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/render/pixel_perfect.dart';

class AnimationAssetConfig {
  const AnimationAssetConfig({
    required this.assetPath,
    required this.frames,
    required this.stepTime,
    required this.frameSize,
    this.loop = true,
  });

  final String assetPath;
  final int frames;
  final double stepTime;
  final Size frameSize;
  final bool loop;
}

class ProjectileAssetConfig {
  const ProjectileAssetConfig({
    required this.assetPath,
    required this.renderSize,
    this.frameSize,
    this.frames = 0,
    this.stepTime = 0,
    this.buildAnimation = false,
  });

  final String assetPath;
  final Size renderSize;
  final Size? frameSize;
  final int frames;
  final double stepTime;
  final bool buildAnimation;
}

class ProjectileAssets {
  const ProjectileAssets({
    required this.renderSize,
    this.sprite,
    this.animation,
  });

  final Size renderSize;
  final Sprite? sprite;
  final SpriteAnimation? animation;
}

class HeroVisualConfig {
  const HeroVisualConfig({
    required this.baseColor,
    required this.spriteScale,
    required this.spriteSize,
    required this.idle,
    required this.walk,
    required this.attack,
    required this.hurt,
    required this.death,
    this.arrowProjectile,
    this.fireballProjectile,
  });

  final Color baseColor;
  final double spriteScale;
  final double spriteSize;
  final AnimationAssetConfig idle;
  final AnimationAssetConfig walk;
  final AnimationAssetConfig attack;
  final AnimationAssetConfig hurt;
  final AnimationAssetConfig death;
  final ProjectileAssetConfig? arrowProjectile;
  final ProjectileAssetConfig? fireballProjectile;

  Future<HeroVisuals> load(
    PixelClashGame game, {
    required Vector2 componentSize,
  }) async {
    final idleImage = await game.images.load(idle.assetPath);
    final walkImage = await game.images.load(walk.assetPath);
    final attackImage = await game.images.load(attack.assetPath);
    final hurtImage = await game.images.load(hurt.assetPath);
    final deathImage = await game.images.load(death.assetPath);

    final idleAnim = _buildAnimation(idleImage, idle);
    final walkAnim = _buildAnimation(walkImage, walk);
    final attackAnim = _buildAnimation(attackImage, attack);
    final hurtAnim = _buildAnimation(hurtImage, hurt);
    final deathAnim = _buildAnimation(deathImage, death);

    final sprite = SpriteAnimationComponent(
      animation: idleAnim,
      size: Vector2.all(spriteSize),
      anchor: Anchor.center,
      position: componentSize / 2,
      paint: pixelPaint(),
    );

    final arrowAssets = await _loadProjectileAssets(game, arrowProjectile);
    final fireballAssets = await _loadProjectileAssets(game, fireballProjectile);

    return HeroVisuals(
      baseColor: baseColor,
      spriteScale: spriteScale,
      sprite: sprite,
      idle: idleAnim,
      walk: walkAnim,
      attack: attackAnim,
      hurt: hurtAnim,
      death: deathAnim,
      attackDurationSec: attack.frames * attack.stepTime,
      hurtDurationSec: hurt.frames * hurt.stepTime,
      deathDurationSec: death.frames * death.stepTime,
      arrowProjectile: arrowAssets,
      fireballProjectile: fireballAssets,
    );
  }
}

class HeroVisuals {
  HeroVisuals({
    required this.baseColor,
    required this.spriteScale,
    required this.sprite,
    required this.idle,
    required this.walk,
    required this.attack,
    required this.hurt,
    required this.death,
    required this.attackDurationSec,
    required this.hurtDurationSec,
    required this.deathDurationSec,
    this.arrowProjectile,
    this.fireballProjectile,
  });

  final Color baseColor;
  final double spriteScale;
  final SpriteAnimationComponent sprite;
  final SpriteAnimation idle;
  final SpriteAnimation walk;
  final SpriteAnimation attack;
  final SpriteAnimation hurt;
  final SpriteAnimation death;
  final double attackDurationSec;
  final double hurtDurationSec;
  final double deathDurationSec;
  final ProjectileAssets? arrowProjectile;
  final ProjectileAssets? fireballProjectile;
}

SpriteAnimation _buildAnimation(ui.Image image, AnimationAssetConfig cfg) {
  return SpriteAnimation.fromFrameData(
    image,
    SpriteAnimationData.sequenced(
      amount: cfg.frames,
      stepTime: cfg.stepTime,
      textureSize: Vector2(cfg.frameSize.width, cfg.frameSize.height),
      loop: cfg.loop,
    ),
  );
}

Future<ProjectileAssets?> _loadProjectileAssets(
  PixelClashGame game,
  ProjectileAssetConfig? config,
) async {
  if (config == null) return null;

  final image = await game.images.load(config.assetPath);
  final frameSize = config.frameSize;
  final sprite = frameSize == null
      ? Sprite(image)
      : Sprite(
          image,
          srcPosition: Vector2.zero(),
          srcSize: Vector2(frameSize.width, frameSize.height),
        );
  sprite.paint = pixelPaint();

  SpriteAnimation? animation;
  if (config.buildAnimation && frameSize != null && config.frames > 0) {
    animation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: config.frames,
        stepTime: config.stepTime,
        textureSize: Vector2(frameSize.width, frameSize.height),
      ),
    );
  }

  return ProjectileAssets(
    renderSize: config.renderSize,
    sprite: sprite,
    animation: animation,
  );
}
