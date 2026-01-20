import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/damageable.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/ui/crit_lightning_component.dart';
import 'package:pixel_clash/game/ui/damage_number_component.dart';
import 'package:pixel_clash/game/ui/hit_particles.dart';

class EnemyComponent extends PositionComponent
    with HasGameReference<PixelClashGame>, CollisionCallbacks
    implements Damageable {
  EnemyComponent({
    required super.position,
    required this.speed,
    required int hp,
    required this.damage,
    required this.scoreReward,
    required this.xpReward,
  })  : _hp = hp,
        _maxHp = hp;

  final double speed;
  final int damage;

  final int scoreReward;
  final int xpReward;

  int _hp;
  final int _maxHp;

  bool _isDead = false;

  @override
  bool get isDead => _isDead;

  late final CircleHitbox _hitbox;

  double _attackCooldown = 0;

  // Замедления/контроль.
  double _slowLeft = 0;
  double _slowPct = 0;
  double _freezeLeft = 0;
  double _stunLeft = 0;
  double _burnLeft = 0;
  double _burnPhase = 0;
  double _burnFxTimer = 0;
  double _bleedLeft = 0;
  double _bleedFxTimer = 0;

  // Последний атакующий (для EnemyKilledEvent).
  PositionComponent? _lastAttacker;

  final List<_DotEffect> _dots = <_DotEffect>[];

  final Color _baseColor = const Color(0xFFE57373);
  final Color _flashColor = const Color(0xFFFFCDD2);

  double _flashTimer = 0;
  static const double _flashDuration = 0.08;

  final Paint _hpBg = Paint()..color = const Color(0x66000000);
  final Paint _hpFg = Paint()..color = const Color(0xFFE53935);
  final Paint _hpBorder = Paint()
    ..color = const Color(0x66FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2.all(28);
    anchor = Anchor.center;

    _hitbox = CircleHitbox(radius: 12);
    add(_hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDead) return;

    _attackCooldown = max(0, _attackCooldown - dt);
    _flashTimer = max(0, _flashTimer - dt);

    _updateStatusTimers(dt);
    _updateDotFx(dt);

    _updateDots(dt);

    _updateMovement(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bodyPaint = Paint()..color = (_flashTimer > 0) ? _flashColor : _baseColor;

    final rect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x,
      height: size.y,
    );
    canvas.drawRect(rect, bodyPaint);

    if (_freezeLeft > 0) {
      _renderFreezeOverlay(canvas, rect);
    }

    if (_burnLeft > 0) {
      _renderBurnOverlay(canvas, rect);
    }

    _renderHpBar(canvas);
  }

  /// Рисуем HP-бар над врагом.
  void _renderHpBar(Canvas canvas) {
    final maxHp = _maxHp;
    final curHp = _hp.clamp(0, _maxHp);

    final ratio = maxHp <= 0 ? 0.0 : (curHp / maxHp).clamp(0.0, 1.0);

    const barW = 30.0;
    const barH = 4.0;

    final cx = size.x / 2;

    final barLeft = cx - barW / 2;
    const barTop = -10.0;

    final barRect = Rect.fromLTWH(barLeft, barTop, barW, barH);

    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
      _hpBg,
    );

    if (ratio > 0) {
      final fill = Rect.fromLTWH(barRect.left, barRect.top, barW * ratio, barH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(fill, const Radius.circular(2)),
        _hpFg,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
      _hpBorder,
    );
  }

  /// Визуал горения: оранжевая пульсация поверх тела.
  void _renderBurnOverlay(Canvas canvas, Rect rect) {
    final t = (sin(_burnPhase) * 0.5 + 0.5).clamp(0.0, 1.0);
    final alpha = 0.25 + 0.30 * t;

    final paint = Paint()..color = const Color(0xFFFF8A50).withValues(alpha: alpha);

    canvas.drawRect(rect, paint);
  }

  /// Визуал заморозки: голубая маска поверх тела.
  void _renderFreezeOverlay(Canvas canvas, Rect rect) {
    const alpha = 0.35;
    final paint = Paint()..color = const Color(0xFF8FD3FF).withValues(alpha: alpha);
    canvas.drawRect(rect, paint);
  }

  /// Обновление таймеров статусов/контролей.
  void _updateStatusTimers(double dt) {
    _slowLeft = max(0, _slowLeft - dt);
    _freezeLeft = max(0, _freezeLeft - dt);
    _stunLeft = max(0, _stunLeft - dt);
    _burnLeft = max(0, _burnLeft - dt);
    _bleedLeft = max(0, _bleedLeft - dt);
    _burnPhase += dt * 8.0;
  }

  /// Визуальные эффекты дотов (поджог/кровотечение).
  void _updateDotFx(double dt) {
    if (_burnLeft > 0) {
      _burnFxTimer -= dt;
      if (_burnFxTimer <= 0) {
        _burnFxTimer = 0.16;
        spawnHitParticles(
          parent: game.worldMap,
          position: position,
          color: const Color(0xFFFF8A50),
          count: 8,
        );
      }
    }

    if (_bleedLeft > 0) {
      _bleedFxTimer -= dt;
      if (_bleedFxTimer <= 0) {
        _bleedFxTimer = 0.18;
        spawnHitParticles(
          parent: game.worldMap,
          position: position,
          color: const Color(0xFFFF5252),
          count: 8,
        );
      }
    }
  }

  /// Движение к игроку с учетом контроля/замедления.
  void _updateMovement(double dt) {
    final p = game.player;
    if (p == null || p.isRemoving) return;

    if (_freezeLeft > 0 || _stunLeft > 0) return;

    final dir = (p.position - position);
    if (dir.length2 > 0.001) {
      dir.normalize();
      final slowMult = (_slowLeft > 0) ? (1.0 - _slowPct) : 1.0;
      position += dir * speed * slowMult * dt;
    }
  }

  // ===== status effects =====

  /// Замедляет врага на время (0..1).
  void applySlow(double pct, double durationSec) {
    if (pct <= 0 || durationSec <= 0) return;
    _slowPct = max(_slowPct, pct.clamp(0.0, 0.95));
    _slowLeft = max(_slowLeft, durationSec);
  }

  /// Заморозка: полный контроль-лок на время.
  void applyFreeze(double durationSec) {
    if (durationSec <= 0) return;
    _freezeLeft = max(_freezeLeft, durationSec);
  }

  /// Оглушение: полный контроль-лок на время.
  void applyStun(double durationSec) {
    if (durationSec <= 0) return;
    _stunLeft = max(_stunLeft, durationSec);
  }

  /// Дот с суммарным уроном от базового урона.
  void applyDot({
    required String id,
    required int baseDamage,
    required double totalDamagePct,
    required double durationSec,
    required double tickSec,
    required PositionComponent? attacker,
  }) {
    if (baseDamage <= 0) return;
    if (totalDamagePct <= 0 || durationSec <= 0 || tickSec <= 0) return;

    final totalDamage = max(1, (baseDamage * totalDamagePct).round());
    final ticks = max(1, (durationSec / tickSec).ceil());
    final damagePerTick = max(1, (totalDamage / ticks).round());

    _dots.removeWhere((d) => d.id == id);
    _dots.add(
      _DotEffect(
        id: id,
        timeLeft: durationSec,
        tickSec: tickSec,
        tickLeft: tickSec,
        damagePerTick: damagePerTick,
        attacker: attacker,
      ),
    );

    if (id == 'ignite') {
      _burnLeft = max(_burnLeft, durationSec);
      _burnFxTimer = 0;
      return;
    }

    if (id == 'bleed') {
      _bleedLeft = max(_bleedLeft, durationSec);
      _bleedFxTimer = 0;
    }
  }

  void _updateDots(double dt) {
    if (_dots.isEmpty) return;

    for (final d in List<_DotEffect>.from(_dots)) {
      d.timeLeft -= dt;
      d.tickLeft -= dt;

      if (d.tickLeft <= 0) {
        d.tickLeft += d.tickSec;
        takeDamageFromHit(
          d.damagePerTick,
          isCrit: false,
          attacker: d.attacker,
          sourceType: DamageSourceType.ability,
          showHitEffects: false,
        );
      }

      if (d.timeLeft <= 0) {
        _dots.remove(d);
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_isDead) return;

    if (other is PlayerComponent) _tryAttack(other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (_isDead) return;

    if (other is PlayerComponent) _tryAttack(other);
  }

  void _tryAttack(PlayerComponent player) {
    if (_attackCooldown > 0) return;
    if (_freezeLeft > 0 || _stunLeft > 0) return;
    _attackCooldown = 0.7;
    player.takeDamage(
      damage,
      attacker: this,
      sourceType: DamageSourceType.melee,
    );
  }

  @override
  void takeDamage(int value) {
    takeDamageFromHit(value, isCrit: false);
  }

  void takeDamageFromHit(
    int value, {
    required bool isCrit,
    PositionComponent? attacker,
    DamageSourceType sourceType = DamageSourceType.unknown,
    bool showHitEffects = true,
  }) {
    if (_isDead) return;

    _lastAttacker = attacker;

    if (showHitEffects) {
      game.requestHitStop(isCrit ? 0.016 : 0.012);

      // Вспышка.
      _flashTimer = _flashDuration;

      // Урон над головой.
      game.worldMap.add(
        DamageNumberComponent(
          position: position + Vector2(0, -18),
          value: value,
          color: isCrit ? const Color(0xFFFFD54F) : const Color(0xFFFFF176),
          scaleFactor: isCrit ? 1.35 : 1.0,
        ),
      );

      // Частицы удара.
      spawnHitParticles(
        parent: game.worldMap,
        position: position,
        color: isCrit ? const Color(0xFFFFD54F) : const Color(0xFFFFF176),
        count: isCrit ? 18 : 12,
      );

      // Молния при крите.
      if (isCrit) {
        game.worldMap.add(
          CritLightningComponent(
            position: position + Vector2(0, -10),
          ),
        );
      }
    }

    _hp -= value;
    if (_hp <= 0) _die();
  }

  void _die() {
    if (_isDead) return;
    _isDead = true;

    _hitbox.collisionType = CollisionType.inactive;

    game.scoreSystem.addScore(scoreReward);
    game.xpSystem.addXp(xpReward);

    final killer = _lastAttacker;
    if (killer is PlayerComponent) {
      killer.buffs.emit(
        EnemyKilledEvent(
          killer: killer,
          enemy: this,
        ),
      );
    }

    Future<void>.microtask(() {
      if (!isRemoving) removeFromParent();
    });
  }
}

class _DotEffect {
  _DotEffect({
    required this.id,
    required this.timeLeft,
    required this.tickSec,
    required this.tickLeft,
    required this.damagePerTick,
    required this.attacker,
  });

  final String id;
  double timeLeft;
  final double tickSec;
  double tickLeft;
  final int damagePerTick;
  final PositionComponent? attacker;
}
