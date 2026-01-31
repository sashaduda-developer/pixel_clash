import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/buff_system.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar_buffs.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/projectile_arrow.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/attack_profile.dart';
import 'package:pixel_clash/game/components/player/hero_definition.dart';
import 'package:pixel_clash/game/components/player/hero_type.dart';
import 'package:pixel_clash/game/components/player/hero_visuals.dart';
import 'package:pixel_clash/game/components/player/player_attack_behavior.dart';
import 'package:pixel_clash/game/components/player/player_stats.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/ui/damage_number_component.dart';
import 'package:pixel_clash/game/ui/hit_particles.dart';

class PlayerComponent extends PositionComponent
    with HasGameReference<PixelClashGame>, CollisionCallbacks
    implements PlayerAttackContext {
  PlayerComponent({
    required this.hero,
    required super.position,
  })  : stats = hero.createStats(),
        attackProfile = hero.attackProfile,
        _attackBehavior = hero.attackBehavior;

  final HeroDefinition hero;
  @override
  final PlayerStats stats;
  @override
  final AttackProfile attackProfile;
  final PlayerAttackBehavior _attackBehavior;

  HeroType get heroType => hero.type;

  int get hp => stats.hp;
  int get maxHp => stats.maxHp;
  @override
  PositionComponent get owner => this;

  @override
  Sprite? get arrowSprite => _arrowSprite;

  @override
  Size? get arrowSpriteSize => _arrowSpriteSize;

  @override
  Sprite? get fireballSprite => _fireballSprite;

  @override
  SpriteAnimation? get fireballAnimation => _fireballAnimation;

  @override
  Size? get fireballSpriteSize => _fireballSpriteSize;

  late final CircleHitbox _hitbox;
  @override
  late final BuffSystem buffs;

  bool _isDead = false;
  bool _facingLeft = false;
  double _attackAnimTimeLeft = 0;
  double _hurtAnimTimeLeft = 0;
  double _deathAnimTimeLeft = 0;
  double _faceOverrideTimeLeft = 0;
  double _invulnerableLeft = 0;
  double _spriteScale = 1.0;
  double _attackAnimDurationSec = 0.0;
  double _hurtAnimDurationSec = 0.0;
  double _deathAnimDurationSec = 0.0;

  SpriteAnimationComponent? _sprite;
  SpriteAnimation? _idleAnimation;
  SpriteAnimation? _walkAnimation;
  SpriteAnimation? _attackAnimation;
  SpriteAnimation? _hurtAnimation;
  SpriteAnimation? _deathAnimation;
  SpriteAnimation? _fireballAnimation;
  Sprite? _arrowSprite;
  Sprite? _fireballSprite;
  Size? _arrowSpriteSize;
  Size? _fireballSpriteSize;

  final Color _flashColor = const Color(0xFFFFFFFF);

  double _flashTimer = 0;
  static const double _flashDuration = 0.08;

  double _attackTimer = 0;
  bool _forceCritNext = false;
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2.all(32);
    anchor = Anchor.center;

    _hitbox = CircleHitbox(radius: 14);
    add(_hitbox);

    game.notifyPlayerStatsChanged();
    buffs = BuffSystem(this);

    final visuals = await hero.visuals.load(
      game,
      componentSize: size,
    );
    _applyVisuals(visuals);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isRewardPauseActive) return;
    if (_isDead) return;

    _flashTimer = max(0, _flashTimer - dt);

    final dir = game.joystick.relativeDelta.clone();
    final isMoving = dir.length2 > 0;
    if (dir.length2 > 0) {
      dir.normalize();
      position += dir * stats.moveSpeed * dt;
      position = game.worldMap.clampToMap(position);
    }
    _updateSpriteAnimation(isMoving, dir);

    _attackTimer += dt;
    final interval = (1.0 / stats.attackSpeed).clamp(0.12, 10.0);
    if (_attackTimer >= interval) {
      if (_autoAttack()) {
        _attackTimer = 0;
      } else {
        _attackTimer = interval;
      }
    }
    _attackAnimTimeLeft = max(0, _attackAnimTimeLeft - dt);
    _hurtAnimTimeLeft = max(0, _hurtAnimTimeLeft - dt);
    _deathAnimTimeLeft = max(0, _deathAnimTimeLeft - dt);
    _faceOverrideTimeLeft = max(0, _faceOverrideTimeLeft - dt);
    _invulnerableLeft = max(0, _invulnerableLeft - dt);

    // Апдейт баффов после перемещения и атаки.
    buffs.update(dt);
    _updateRegen(dt);
  }

  bool _autoAttack() {
    return _attackBehavior.tryAttack(this);
  }

  /// Роллим урон и флаг крита.
  @override
  (int, bool) rollDamage() {
    final base = stats.damage;

    if (_forceCritNext) {
      _forceCritNext = false;
      final evasionBuff =
          buffs.getBuffAs<SamuraiEvasionStrikeBuff>('buff_samurai_evasion_strike');
      final bonus = evasionBuff?.critBonusMultiplier ?? 0.0;
      final dmg = (base * (stats.critMultiplier + bonus)).round();
      return (dmg, true);
    }

    final r = game.rng.nextDouble();
    final isCrit = r < stats.critChance;
    final dmg = isCrit ? (base * stats.critMultiplier).round() : base;

    return (dmg, isCrit);
  }

  @override
  bool rollChance(double chance) {
    if (chance <= 0) return false;
    final clamped = chance.clamp(0.0, 1.0);
    return game.rng.nextDouble() < clamped;
  }

  @override
  EnemyComponent? findNearestEnemyInRange({
    required bool onlyVisibleOnScreen,
    required double range,
  }) {
    EnemyComponent? best;
    double bestDist2 = double.infinity;

    final visible = game.cam.visibleWorldRect.inflate(60);

    for (final c in game.worldMap.children) {
      if (c is! EnemyComponent) continue;
      if (c.isDead || c.isRemoving) continue;

      if (onlyVisibleOnScreen) {
        final p = c.position;
        if (!visible.contains(Offset(p.x, p.y))) continue;
      }

      final d2 = c.position.distanceToSquared(position);
      if (d2 > range * range) continue;

      if (d2 < bestDist2) {
        bestDist2 = d2;
        best = c;
      }
    }

    return best;
  }

  @override
  void shootProjectile({
    required Vector2 direction,
    required int damage,
    required bool isCrit,
    required double speed,
    required Color color,
    required Size size,
    required DamageSourceType sourceType,
    ProjectileVisual visual = ProjectileVisual.bolt,
    int? pierceOverride,
    int? ricochetOverride,
    double? ricochetMultiplierOverride,
    Sprite? spriteOverride,
    SpriteAnimation? spriteAnimationOverride,
    double? angleOffset,
  }) {
    final (pierceCount, ricochetBounces, ricochetMultiplier) = _projectileModifiers();
    final finalPierce = pierceOverride ?? pierceCount;
    final finalRicochet = ricochetOverride ?? ricochetBounces;
    final finalRicochetMult = ricochetMultiplierOverride ?? ricochetMultiplier;

    final proj = ProjectileArrow(
      owner: this,
      position: position.clone(),
      direction: direction,
      speed: speed,
      damage: damage,
      isCrit: isCrit,
      sourceType: sourceType,
      paintColor: color,
      sizeOverride: Vector2(size.width, size.height),
      visual: visual,
      sprite: spriteOverride,
      spriteAnimation: spriteAnimationOverride,
      angleOffset: angleOffset ?? 0.0,
      pierceCount: finalPierce,
      ricochetBounces: finalRicochet,
      ricochetDamageMultiplier: finalRicochetMult,
    );

    game.worldMap.add(proj);
  }

  (int, int, double) _projectileModifiers() {
    final pierceBuff = buffs.getBuffAs<PiercingProjectilesBuff>('buff_piercing_projectiles');
    final ricochetBuff = buffs.getBuffAs<RicochetBuff>('buff_ricochet');

    final pierceCount = pierceBuff?.pierceCount ?? 0;
    final ricochetBounces = ricochetBuff?.bounces ?? 0;
    final ricochetMultiplier = ricochetBuff?.damageMultiplier ?? 0.0;

    return (pierceCount, ricochetBounces, ricochetMultiplier);
  }

  void _updateRegen(double dt) {
    var changed = false;
    if (stats.regenMana(dt)) {
      changed = true;
    }
    if (stats.regenHp(dt)) {
      changed = true;
    }
    if (changed) {
      game.notifyPlayerStatsChanged();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_sprite != null) return;
    super.render(canvas);

    final base = _heroBaseColor();
    final color = (_flashTimer > 0) ? _flashColor : base;

    final rect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x,
      height: size.y,
    );

    canvas.drawRect(rect, Paint()..color = color);

    final border = Paint()
      ..color = const Color(0xAA000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, border);
  }

  void _applyVisuals(HeroVisuals visuals) {
    _sprite = visuals.sprite;
    _idleAnimation = visuals.idle;
    _walkAnimation = visuals.walk;
    _attackAnimation = visuals.attack;
    _hurtAnimation = visuals.hurt;
    _deathAnimation = visuals.death;
    _spriteScale = visuals.spriteScale;
    _attackAnimDurationSec = visuals.attackDurationSec;
    _hurtAnimDurationSec = visuals.hurtDurationSec;
    _deathAnimDurationSec = visuals.deathDurationSec;

    _arrowSprite = visuals.arrowProjectile?.sprite;
    _arrowSpriteSize = visuals.arrowProjectile?.renderSize;
    _fireballSprite = visuals.fireballProjectile?.sprite;
    _fireballAnimation = visuals.fireballProjectile?.animation;
    _fireballSpriteSize = visuals.fireballProjectile?.renderSize;

    add(visuals.sprite);
  }

  void _updateSpriteAnimation(bool isMoving, Vector2 dir) {
    final sprite = _sprite;
    if (sprite == null) return;

    if (_attackAnimTimeLeft <= 0 &&
        _hurtAnimTimeLeft <= 0 &&
        _faceOverrideTimeLeft <= 0 &&
        isMoving) {
      if (dir.x < -0.01) {
        _facingLeft = true;
      } else if (dir.x > 0.01) {
        _facingLeft = false;
      }
    }

    final nextAnimation = (_deathAnimTimeLeft > 0 && _deathAnimation != null)
        ? _deathAnimation
        : (_hurtAnimTimeLeft > 0 && _hurtAnimation != null)
            ? _hurtAnimation
            : (_attackAnimTimeLeft > 0 && _attackAnimation != null)
                ? _attackAnimation
                : (isMoving ? _walkAnimation : _idleAnimation);
    if (nextAnimation != null && sprite.animation != nextAnimation) {
      sprite.animation = nextAnimation;
    }

    final dirScale = _facingLeft ? -1.0 : 1.0;
    sprite.scale = Vector2(dirScale * _spriteScale, _spriteScale);
  }

  @override
  void triggerAttackAnimation() {
    if (_attackAnimation == null) return;
    _attackAnimTimeLeft = _attackAnimDurationSec;
  }

  @override
  void setFacingForAttack(Vector2 dir) {
    if (dir.length2 <= 0.0001) return;
    _facingLeft = dir.x < 0;
    _faceOverrideTimeLeft = _attackAnimDurationSec;
  }

  @override
  double attackImpactDelaySec() {
    return max(0.02, _attackAnimDurationSec * 0.85);
  }

  @override
  void scheduleAttackImpact({
    required double delay,
    required void Function() action,
  }) {
    game.worldMap.add(
      TimerComponent(
        period: delay,
        repeat: false,
        onTick: () {
          if (_isDead || isRemoving) return;
          action();
        },
      ),
    );
  }

  @override
  void addWorldComponent(Component component) {
    game.worldMap.add(component);
  }

  @override
  void notifyStatsChanged() {
    game.notifyPlayerStatsChanged();
  }

  @override
  void setAttackTimer(double value) {
    _attackTimer = value;
  }

  void takeDamage(
    int rawDamage, {
    PositionComponent? attacker,
    DamageSourceType sourceType = DamageSourceType.unknown,
  }) {
    if (_isDead) return;

    // Шанс уклониться от удара.
    final evade = stats.evasionChance.clamp(0.0, 0.80);
    if (evade > 0 && game.rng.nextDouble() < evade) {
    final evadeBuff =
        buffs.getBuffAs<SamuraiEvasionStrikeBuff>('buff_samurai_evasion_strike');
      if (evadeBuff != null) {
        _forceCritNext = true;
      }
      // Визуальный фидбек уклонения.
      game.worldMap.add(
        DamageNumberComponent(
          position: position + Vector2(0, -24),
          value: 0,
          label: game.l10n.t('combat_miss'),
          color: const Color(0xFFB0BEC5),
          scaleFactor: 0.95,
        ),
      );
      return;
    }

    if (_invulnerableLeft > 0) return;

    var dmg = max(1, rawDamage - stats.armor);
    dmg = buffs.modifyIncomingDamage(
      dmg,
      sourceType: sourceType,
      attacker: attacker,
    );
    if (sourceType == DamageSourceType.melee) {
      if (heroType == HeroType.samurai) {
        dmg = max(1, (dmg * 0.88).round());
      } else if (heroType == HeroType.knight) {
        dmg = max(1, (dmg * 0.97).round());
      }
    }
    if (dmg <= 0) return;

    // Пробрасываем атакующего для отражения/реакций баффов.
    buffs.emit(
      DamageTakenEvent(
        victim: this,
        attacker: attacker,
        amount: dmg,
        sourceType: sourceType,
      ),
    );

    stats.hp -= dmg;
    _hurtAnimTimeLeft = _hurtAnimDurationSec;

    // hit-stop
    game.requestHitStop(0.018);

    // вспышка
    _flashTimer = _flashDuration;

    // урон над головой
    game.worldMap.add(
      DamageNumberComponent(
        position: position + Vector2(0, -22),
        value: dmg,
        color: const Color(0xFFFF5252),
      ),
    );

    // частицы
    spawnHitParticles(
      parent: game.worldMap,
      position: position,
      color: const Color(0xFFFF5252),
      count: 14,
    );

    game.notifyPlayerStatsChanged();

    if (stats.hp <= 0) _die();
  }

  void _die() {
    if (_isDead) return;
    _isDead = true;
    stats.hp = 0;

    game.notifyPlayerStatsChanged();

    _hitbox.collisionType = CollisionType.inactive;
    _deathAnimTimeLeft = _deathAnimDurationSec;
    if (_sprite != null && _deathAnimation != null) {
      _sprite!.animation = _deathAnimation;
    }

    game.worldMap.add(
      TimerComponent(
        period: _deathAnimDurationSec,
        repeat: false,
        onTick: () {
          if (!isRemoving) removeFromParent();
          game.onPlayerDied();
        },
      ),
    );
  }

  Color _heroBaseColor() {
    return hero.visuals.baseColor;
  }

  void grantInvulnerability(double durationSec) {
    if (durationSec <= 0) return;
    _invulnerableLeft = max(_invulnerableLeft, durationSec);
  }
}
