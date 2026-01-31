import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/render/pixel_perfect.dart';

class AnimatedEnemyConfig {
  const AnimatedEnemyConfig({
    required this.basePath,
    required this.idleFile,
    required this.walkFile,
    required this.attackFile,
    required this.hurtFile,
    required this.deathFile,
    required this.idleFrames,
    required this.walkFrames,
    required this.attackFrames,
    required this.hurtFrames,
    required this.deathFrames,
    this.idleStepTime = 0.12,
    this.walkStepTime = 0.10,
    this.attackStepTime = 0.07,
    this.hurtStepTime = 0.07,
    this.deathStepTime = 0.10,
    this.spriteScale = 1.6,
    this.attackDelaySec = 0.14,
    this.frameSize = const Size(100, 100),
  });

  final String basePath;
  final String idleFile;
  final String walkFile;
  final String attackFile;
  final String hurtFile;
  final String deathFile;

  final int idleFrames;
  final int walkFrames;
  final int attackFrames;
  final int hurtFrames;
  final int deathFrames;

  final double idleStepTime;
  final double walkStepTime;
  final double attackStepTime;
  final double hurtStepTime;
  final double deathStepTime;

  final double spriteScale;
  final double attackDelaySec;
  final Size frameSize;
}

class AnimatedEnemyComponent extends EnemyComponent {
  AnimatedEnemyComponent({
    required super.position,
    required super.speed,
    required super.hp,
    required super.damage,
    required super.scoreReward,
    required super.xpReward,
    required this.config,
  });

  final AnimatedEnemyConfig config;

  SpriteAnimationComponent? _sprite;
  SpriteAnimation? _idleAnimation;
  SpriteAnimation? _walkAnimation;
  SpriteAnimation? _attackAnimation;
  SpriteAnimation? _hurtAnimation;
  SpriteAnimation? _deathAnimation;

  bool _facingLeft = false;
  double _attackAnimTimeLeft = 0;
  double _hurtAnimTimeLeft = 0;

  double get _attackAnimDuration => config.attackFrames * config.attackStepTime;
  double get _hurtAnimDuration => config.hurtFrames * config.hurtStepTime;
  double get _deathAnimDuration => config.deathFrames * config.deathStepTime;

  @override
  double get meleeAttackDelaySec => config.attackDelaySec;

  @override
  double get deathDespawnDelaySec => _deathAnimDuration;

  @override
  bool get drawBody => _sprite == null;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadSprite();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;
    _attackAnimTimeLeft = (_attackAnimTimeLeft - dt).clamp(0.0, 10.0);
    _hurtAnimTimeLeft = (_hurtAnimTimeLeft - dt).clamp(0.0, 10.0);
    _updateSpriteAnimation();
  }

  Future<void> _loadSprite() async {
    final idleImage = await game.images.load('${config.basePath}${config.idleFile}');
    final walkImage = await game.images.load('${config.basePath}${config.walkFile}');
    final attackImage = await game.images.load('${config.basePath}${config.attackFile}');
    final hurtImage = await game.images.load('${config.basePath}${config.hurtFile}');
    final deathImage = await game.images.load('${config.basePath}${config.deathFile}');

    _idleAnimation = _buildAnimation(
      idleImage,
      frames: config.idleFrames,
      stepTime: config.idleStepTime,
      loop: true,
    );
    _walkAnimation = _buildAnimation(
      walkImage,
      frames: config.walkFrames,
      stepTime: config.walkStepTime,
      loop: true,
    );
    _attackAnimation = _buildAnimation(
      attackImage,
      frames: config.attackFrames,
      stepTime: config.attackStepTime,
      loop: true,
    );
    _hurtAnimation = _buildAnimation(
      hurtImage,
      frames: config.hurtFrames,
      stepTime: config.hurtStepTime,
      loop: true,
    );
    _deathAnimation = _buildAnimation(
      deathImage,
      frames: config.deathFrames,
      stepTime: config.deathStepTime,
      loop: false,
    );

    _sprite = SpriteAnimationComponent(
      animation: _idleAnimation,
      size: Vector2(config.frameSize.width, config.frameSize.height),
      anchor: Anchor.center,
      position: size / 2,
      paint: pixelPaint(),
    );
    _sprite!.scale = Vector2(config.spriteScale, config.spriteScale);
    add(_sprite!);
  }

  SpriteAnimation _buildAnimation(
    ui.Image image, {
    required int frames,
    required double stepTime,
    required bool loop,
  }) {
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTime,
        textureSize: Vector2(config.frameSize.width, config.frameSize.height),
        loop: loop,
      ),
    );
  }

  void _updateSpriteAnimation() {
    final sprite = _sprite;
    final player = game.player;
    if (sprite == null || player == null) return;

    final dir = (player.position - position);
    final isMoving = dir.length2 > 4.0;
    if (_attackAnimTimeLeft <= 0 && _hurtAnimTimeLeft <= 0) {
      if (dir.x < -0.01) {
        _facingLeft = true;
      } else if (dir.x > 0.01) {
        _facingLeft = false;
      }
    }

    final nextAnimation = (_hurtAnimTimeLeft > 0 && _hurtAnimation != null)
        ? _hurtAnimation
        : (_attackAnimTimeLeft > 0 && _attackAnimation != null)
            ? _attackAnimation
            : (isMoving ? _walkAnimation : _idleAnimation);
    if (nextAnimation != null && sprite.animation != nextAnimation) {
      sprite.animation = nextAnimation;
    }

    final dirScale = _facingLeft ? -1.0 : 1.0;
    sprite.scale = Vector2(dirScale * config.spriteScale, config.spriteScale);
  }

  @override
  void onMeleeAttack() {
    final player = game.player;
    if (player == null) return;
    _facingLeft = player.position.x < position.x;
    _attackAnimTimeLeft = _attackAnimDuration;
  }

  @override
  void onDamageTaken() {
    _hurtAnimTimeLeft = _hurtAnimDuration;
  }

  @override
  void onDeath() {
    _attackAnimTimeLeft = 0;
    _hurtAnimTimeLeft = 0;
    if (_sprite != null && _deathAnimation != null) {
      _sprite!.animation = _deathAnimation;
    }
  }
}
