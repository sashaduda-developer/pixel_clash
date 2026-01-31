import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/ui/hit_particles.dart';

enum _LancerAttackAnim {
  basic,
  charge,
  slam,
}

class LancerBossComponent extends EnemyComponent {
  LancerBossComponent({
    required super.position,
    super.speed = 78,
    super.hp = 420,
    super.damage = 20,
    super.scoreReward = 90,
    super.xpReward = 65,
  });

  // ===== visuals =====
  static const String _basePath = 'enemies/Lancer/';
  static const Size _frameSize = Size(100, 100);
  static const double _spriteScale = 4.0;

  static const double _idleStep = 0.12;
  static const double _walkStep = 0.10;
  static const double _attackStep = 0.08;
  static const double _attackChargeStep = 0.07;
  static const double _attackSlamStep = 0.08;
  static const double _hurtStep = 0.07;
  static const double _deathStep = 0.10;

  static const int _idleFrames = 6;
  static const int _walkFrames = 8;
  static const int _walkAltFrames = 8;
  static const int _attackFrames = 6;
  static const int _attackChargeFrames = 9;
  static const int _attackSlamFrames = 8;
  static const int _hurtFrames = 4;
  static const int _deathFrames = 4;

  SpriteAnimationComponent? _sprite;
  SpriteAnimation? _idleAnimation;
  SpriteAnimation? _walkAnimation;
  SpriteAnimation? _walkAltAnimation;
  SpriteAnimation? _attackAnimation;
  SpriteAnimation? _attackChargeAnimation;
  SpriteAnimation? _attackSlamAnimation;
  SpriteAnimation? _hurtAnimation;
  SpriteAnimation? _deathAnimation;

  bool _facingLeft = false;
  double _attackAnimLeft = 0;
  double _hurtAnimLeft = 0;
  _LancerAttackAnim _attackAnimType = _LancerAttackAnim.basic;

  // ===== abilities =====
  static const double _chargeCooldown = 6.5;
  static const double _chargeWindup = 0.55;
  static const double _dashDuration = 0.32;
  static const double _dashSpeed = 720;
  static const double _dashDamageMult = 1.8;

  static const double _slamCooldown = 7.5;
  static const double _slamWindup = 0.65;
  static const double _slamRadius = 170;
  static const double _slamDamageMult = 1.6;

  double _chargeCooldownLeft = 2.5;
  double _slamCooldownLeft = 4.0;

  bool _abilityLock = false;
  double _dashLeft = 0;
  Vector2 _dashDir = Vector2.zero();
  bool _dashHitDone = false;
  double _dashFxLeft = 0;

  double get _attackAnimDuration => _attackFrames * _attackStep;
  double get _attackChargeDuration => _attackChargeFrames * _attackChargeStep;
  double get _attackSlamDuration => _attackSlamFrames * _attackSlamStep;
  double get _hurtAnimDuration => _hurtFrames * _hurtStep;
  double get _deathAnimDuration => _deathFrames * _deathStep;

  @override
  bool get isBoss => true;

  @override
  String get bossName => game.l10n.t('boss_lancer');

  @override
  Color get baseColor => const Color(0xFFB0BEC5);

  @override
  Color get flashColor => const Color(0xFFECEFF1);

  @override
  Color get hpFillColor => const Color(0xFFEF5350);

  @override
  double get bodySize => 78;

  @override
  double get hitboxRadius => 34;

  @override
  double get hpBarHeight => 7.0;

  @override
  bool get drawEliteBorder => true;

  @override
  Color get eliteBorderColor => const Color(0x99FFFFFF);

  @override
  bool get drawBody => _sprite == null;

  @override
  double get meleeAttackDelaySec => 0.18;

  @override
  double get deathDespawnDelaySec => _deathAnimDuration;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadSprite();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isRewardPauseActive) return;

    _attackAnimLeft = max(0, _attackAnimLeft - dt);
    _hurtAnimLeft = max(0, _hurtAnimLeft - dt);

    _chargeCooldownLeft = max(0, _chargeCooldownLeft - dt);
    _slamCooldownLeft = max(0, _slamCooldownLeft - dt);

    _updateDash(dt);
    _tryStartAbilities();
    _updateSpriteAnimation();
  }

  @override
  void onMeleeAttack() {
    _startAttackAnim(_LancerAttackAnim.basic, _attackAnimDuration);
  }

  @override
  void onDamageTaken() {
    _hurtAnimLeft = _hurtAnimDuration;
  }

  @override
  void onDeath() {
    _attackAnimLeft = 0;
    _hurtAnimLeft = 0;
    if (_sprite != null && _deathAnimation != null) {
      _sprite!.animation = _deathAnimation;
    }
  }

  Future<void> _loadSprite() async {
    final idleImage = await game.images.load('${_basePath}Lancer-Idle.png');
    final walkImage = await game.images.load('${_basePath}Lancer-Walk.png');
    final walkAltImage = await game.images.load('${_basePath}Lancer-Walk02.png');
    final attackImage = await game.images.load('${_basePath}Lancer-Attack.png');
    final attack02Image = await game.images.load('${_basePath}Lancer-Attack02.png');
    final attack03Image = await game.images.load('${_basePath}Lancer-Attack03.png');
    final hurtImage = await game.images.load('${_basePath}Lancer-Hurt.png');
    final deathImage = await game.images.load('${_basePath}Lancer-Death.png');

    _idleAnimation =
        _buildAnimation(idleImage, frames: _idleFrames, stepTime: _idleStep, loop: true);
    _walkAnimation =
        _buildAnimation(walkImage, frames: _walkFrames, stepTime: _walkStep, loop: true);
    _walkAltAnimation =
        _buildAnimation(walkAltImage, frames: _walkAltFrames, stepTime: _walkStep, loop: true);
    _attackAnimation =
        _buildAnimation(attackImage, frames: _attackFrames, stepTime: _attackStep, loop: true);
    _attackChargeAnimation = _buildAnimation(
      attack02Image,
      frames: _attackChargeFrames,
      stepTime: _attackChargeStep,
      loop: true,
    );
    _attackSlamAnimation = _buildAnimation(
      attack03Image,
      frames: _attackSlamFrames,
      stepTime: _attackSlamStep,
      loop: true,
    );
    _hurtAnimation =
        _buildAnimation(hurtImage, frames: _hurtFrames, stepTime: _hurtStep, loop: true);
    _deathAnimation =
        _buildAnimation(deathImage, frames: _deathFrames, stepTime: _deathStep, loop: false);

    _sprite = SpriteAnimationComponent(
      animation: _idleAnimation,
      size: Vector2(_frameSize.width, _frameSize.height),
      anchor: Anchor.center,
      position: size / 2,
    );
    _sprite!.scale = Vector2(_spriteScale, _spriteScale);
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
        textureSize: Vector2(_frameSize.width, _frameSize.height),
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
    if (_attackAnimLeft <= 0 && _hurtAnimLeft <= 0) {
      if (dir.x < -0.01) {
        _facingLeft = true;
      } else if (dir.x > 0.01) {
        _facingLeft = false;
      }
    }

    final nextAnimation = (_hurtAnimLeft > 0 && _hurtAnimation != null)
        ? _hurtAnimation
        : (_attackAnimLeft > 0 ? _attackAnimationForType() : _walkOrIdle(isMoving));
    if (nextAnimation != null && sprite.animation != nextAnimation) {
      sprite.animation = nextAnimation;
    }

    final dirScale = _facingLeft ? -1.0 : 1.0;
    sprite.scale = Vector2(dirScale * _spriteScale, _spriteScale);
  }

  SpriteAnimation? _attackAnimationForType() {
    return switch (_attackAnimType) {
      _LancerAttackAnim.basic => _attackAnimation,
      _LancerAttackAnim.charge => _attackChargeAnimation,
      _LancerAttackAnim.slam => _attackSlamAnimation,
    };
  }

  SpriteAnimation? _walkOrIdle(bool isMoving) {
    if (!isMoving) return _idleAnimation;
    final useAltWalk = (hp / maxHp) < 0.45;
    return useAltWalk ? _walkAltAnimation : _walkAnimation;
  }

  void _startAttackAnim(_LancerAttackAnim type, double duration) {
    _attackAnimType = type;
    _attackAnimLeft = max(_attackAnimLeft, duration);
  }

  void _tryStartAbilities() {
    if (_abilityLock || _dashLeft > 0) return;

    final player = game.player;
    if (player == null || player.isRemoving) return;

    final dist2 = player.position.distanceToSquared(position);
    if (_chargeCooldownLeft <= 0 && dist2 > 180 * 180) {
      _startCharge(player);
      return;
    }

    if (_slamCooldownLeft <= 0 && dist2 < 220 * 220) {
      _startSlam(player);
    }
  }

  void _startCharge(PlayerComponent player) {
    final dir = player.position - position;
    if (dir.length2 <= 0.001) return;

    dir.normalize();
    _abilityLock = true;
    _chargeCooldownLeft = _chargeCooldown;
    _startAttackAnim(_LancerAttackAnim.charge, _attackChargeDuration + _dashDuration);

    game.worldMap.add(
      _LancerChargeTelegraph(
        position: position.clone(),
        direction: dir.clone(),
        length: 260,
        duration: _chargeWindup,
      ),
    );

    game.worldMap.add(
      TimerComponent(
        period: _chargeWindup,
        repeat: false,
        onTick: () {
          if (isDead) return;
          _beginDash(dir);
        },
      ),
    );
  }

  void _beginDash(Vector2 dir) {
    _dashLeft = _dashDuration;
    _dashDir = dir.clone();
    _dashHitDone = false;
    _dashFxLeft = 0.0;
  }

  void _updateDash(double dt) {
    if (_dashLeft <= 0) return;

    _dashLeft = max(0, _dashLeft - dt);
    position += _dashDir * _dashSpeed * dt;
    position = game.worldMap.clampToMap(position);

    _dashFxLeft -= dt;
    if (_dashFxLeft <= 0) {
      _dashFxLeft = 0.06;
      spawnHitParticles(
        parent: game.worldMap,
        position: position.clone(),
        color: const Color(0xFFB39DDB),
        count: 8,
      );
    }

    final player = game.player;
    if (!_dashHitDone && player != null && !player.isRemoving) {
      final r = hitboxRadius + 14;
      if (player.position.distanceToSquared(position) <= r * r) {
        _dashHitDone = true;
        final dmg = max(1, (damage * _dashDamageMult).round());
        player.takeDamage(
          dmg,
          attacker: this,
          sourceType: DamageSourceType.ability,
        );
        spawnHitParticles(
          parent: game.worldMap,
          position: player.position.clone(),
          color: const Color(0xFFD1C4E9),
          count: 14,
        );
      }
    }

    if (_dashLeft <= 0) {
      _abilityLock = false;
    }
  }

  void _startSlam(PlayerComponent player) {
    _abilityLock = true;
    _slamCooldownLeft = _slamCooldown;
    _startAttackAnim(_LancerAttackAnim.slam, _attackSlamDuration);

    final center = position.clone();
    game.worldMap.add(
      _LancerShockwaveTelegraph(
        position: center,
        radius: _slamRadius,
        duration: _slamWindup,
      ),
    );

    game.worldMap.add(
      TimerComponent(
        period: _slamWindup,
        repeat: false,
        onTick: () {
          if (isDead) return;
          _doSlam(center);
          _abilityLock = false;
        },
      ),
    );
  }

  void _doSlam(Vector2 center) {
    game.worldMap.add(
      _LancerShockwaveRing(
        position: center,
        radius: _slamRadius,
        duration: 0.28,
      ),
    );

    spawnHitParticles(
      parent: game.worldMap,
      position: center.clone(),
      color: const Color(0xFFFF5252),
      count: 20,
    );

    final player = game.player;
    if (player == null || player.isRemoving) return;
    if (player.position.distanceToSquared(center) > _slamRadius * _slamRadius) return;

    final dmg = max(1, (damage * _slamDamageMult).round());
    player.takeDamage(
      dmg,
      attacker: this,
      sourceType: DamageSourceType.ability,
    );
  }
}

class _LancerChargeTelegraph extends PositionComponent {
  _LancerChargeTelegraph({
    required super.position,
    required Vector2 direction,
    required this.length,
    required this.duration,
  }) : _angle = atan2(direction.y, direction.x) {
    anchor = Anchor.center;
  }

  final double length;
  final double duration;
  final double _angle;
  double _life = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    if (_life >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final t = (_life / duration).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);

    canvas.save();
    canvas.rotate(_angle);

    const start = 18.0;
    final end = length;
    final glow = Paint()
      ..color = const Color(0xFFCE93D8).withValues(alpha: alpha * 0.6)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final main = Paint()
      ..color = const Color(0xFFFFC4E8).withValues(alpha: alpha)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(start, 0), Offset(end, 0), glow);
    canvas.drawLine(const Offset(start, 0), Offset(end, 0), main);

    canvas.restore();
  }
}

class _LancerShockwaveTelegraph extends PositionComponent {
  _LancerShockwaveTelegraph({
    required super.position,
    required this.radius,
    required this.duration,
  }) {
    anchor = Anchor.center;
  }

  final double radius;
  final double duration;
  double _life = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    if (_life >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final t = (_life / duration).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(0xFFFF8A65).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, radius, paint);
  }
}

class _LancerShockwaveRing extends PositionComponent {
  _LancerShockwaveRing({
    required super.position,
    required this.radius,
    required this.duration,
  }) {
    anchor = Anchor.center;
  }

  final double radius;
  final double duration;
  double _life = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    if (_life >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final t = (_life / duration).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);
    final r = radius * t;

    final paint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(Offset.zero, r, paint);
  }
}
