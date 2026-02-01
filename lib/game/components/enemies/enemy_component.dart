import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/damageable.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/components/interactables/solid_obstacle.dart';
import 'package:pixel_clash/game/components/xp/xp_crystal_component.dart';
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

  int get hp => _hp;
  int get maxHp => _maxHp;
  bool get isBoss => false;
  String get bossName => game.l10n.t('boss_generic');

  bool _isDead = false;
  bool _showHpBar = false;

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

  // Простое избегание препятствий.
  Vector2 _avoidDir = Vector2.zero();
  double _avoidTimeLeft = 0;
  Vector2 _lastPos = Vector2.zero();
  double _stuckTime = 0;
  double _stuckCooldown = 0;
  int _stuckTurn = 1;
  Vector2 _wallFollowDir = Vector2.zero();
  double _wallFollowLeft = 0;
  double _cornerTime = 0;
  List<Vector2> _path = <Vector2>[];
  int _pathIndex = 0;
  double _pathRecalcLeft = 0;

  // Последний атакующий (для EnemyKilledEvent).
  PositionComponent? _lastAttacker;

  final List<_DotEffect> _dots = <_DotEffect>[];

  Color get baseColor => const Color(0xFFE57373);
  Color get flashColor => const Color(0xFFFFCDD2);
  Color get hpFillColor => const Color(0xFFE53935);
  double get bodySize => 28;
  double get hitboxRadius => 12;
  double get hpBarHeight => 4.0;
  bool get drawEliteBorder => false;
  Color get eliteBorderColor => const Color(0x66FFFFFF);
  bool get drawBody => true;
  double get meleeAttackDelaySec => 0.0;
  void onDamageTaken() {}
  void onDeath() {}
  double get deathDespawnDelaySec => 0.0;

  double _flashTimer = 0;
  static const double _flashDuration = 0.08;

  final Paint _hpBg = Paint()..color = const Color(0x66000000);
  final Paint _hpBorder = Paint()
    ..color = const Color(0x66FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2.all(bodySize);
    anchor = Anchor.center;
    _lastPos = position.clone();

    _hitbox = CircleHitbox(radius: hitboxRadius);
    add(_hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isRewardPauseActive) return;
    if (_isDead) return;
    if (isBoss) {
      game.setBossHud(bossName, _hp, _maxHp);
    }

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

    if (drawBody) {
      final bodyPaint = Paint()..color = (_flashTimer > 0) ? flashColor : baseColor;

      final rect = Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x,
        height: size.y,
      );
      canvas.drawRect(rect, bodyPaint);

      if (drawEliteBorder) {
        final border = Paint()
          ..color = eliteBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRect(rect, border);
      }

      if (_freezeLeft > 0) {
        _renderFreezeOverlay(canvas, rect);
      }

      if (_burnLeft > 0) {
        _renderBurnOverlay(canvas, rect);
      }
    }

    if (_showHpBar) {
      _renderHpBar(canvas);
    }
  }

  /// Рисуем HP-бар над врагом.
  void _renderHpBar(Canvas canvas) {
    final maxHp = _maxHp;
    final curHp = _hp.clamp(0, _maxHp);

    final ratio = maxHp <= 0 ? 0.0 : (curHp / maxHp).clamp(0.0, 1.0);

    const barW = 30.0;
    final barH = hpBarHeight;

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
        Paint()..color = hpFillColor,
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
    _avoidTimeLeft = max(0, _avoidTimeLeft - dt);
    _stuckCooldown = max(0, _stuckCooldown - dt);
    _wallFollowLeft = max(0, _wallFollowLeft - dt);
    _cornerTime = max(0, _cornerTime - dt);
    _pathRecalcLeft = max(0, _pathRecalcLeft - dt);
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

    final Vector2 targetPos = p.position.clone();
    final collisionRects = game.worldMap.collisionRects;
    if (_pathRecalcLeft <= 0) {
      _pathRecalcLeft = 0.7;
      if (_hasLineOfSight(position, targetPos, collisionRects)) {
        _path = <Vector2>[];
        _pathIndex = 0;
      } else {
        _path = game.worldMap.findPath(position, targetPos);
        _pathIndex = 0;
      }
    }

    var target = targetPos.clone();
    if (_path.isNotEmpty) {
      while (_pathIndex < _path.length &&
          position.distanceToSquared(_path[_pathIndex]) < 24 * 24) {
        _pathIndex += 1;
      }
      if (_pathIndex < _path.length) {
        target = _path[_pathIndex];
      } else {
        _path = <Vector2>[];
        _pathIndex = 0;
      }
    }

    final dir = (target - position);
    if (dir.length2 <= 0.001) return;

    dir.normalize();
    var moveDir = dir;
    Vector2 avoid = Vector2.zero();

    if (_path.isNotEmpty) {
      _wallFollowLeft = 0;
      _avoidTimeLeft = 0;
    } else if (_wallFollowLeft > 0 && _wallFollowDir.length2 > 0.001) {
      final blended = (dir * 0.35) + (_wallFollowDir * 1.0);
      if (blended.length2 > 0.001) {
        blended.normalize();
        moveDir = blended;
      } else {
        moveDir = _wallFollowDir;
      }
    } else {
    // Дополнительное избегание препятствий по карте.
    avoid = _computeObstacleAvoidance(dir);
    if (avoid.length2 > 0.001) {
      final blended = (dir * 0.7) + (avoid * 0.5);
      if (blended.length2 > 0.001) {
        blended.normalize();
        moveDir = blended;
      }
    } else if (_avoidTimeLeft > 0 && _avoidDir.length2 > 0.001) {
      // Небольшое смешивание направления к игроку и ухода от препятствия.
      final blended = (dir * 0.6) + (_avoidDir * 0.8);
      if (blended.length2 > 0.001) {
        blended.normalize();
        moveDir = blended;
      }
    }
    }

    final slowMult = (_slowLeft > 0) ? (1.0 - _slowPct) : 1.0;
    position += moveDir * speed * slowMult * dt;

    if (_path.isEmpty) {
      _updateStuckState(dir, avoid, p.position, dt);
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

    if (other is PlayerComponent) {
      _resolvePlayerOverlap(other);
      _tryAttack(other);
    }

    if (other is SolidObstacle) {
      _resolveObstacleCollision(other.collisionRect);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (_isDead) return;

    if (other is PlayerComponent) {
      _resolvePlayerOverlap(other);
      _tryAttack(other);
    }

    if (other is SolidObstacle) {
      _resolveObstacleCollision(other.collisionRect);
    }
  }

  void _tryAttack(PlayerComponent player) {
    if (_attackCooldown > 0) return;
    if (_freezeLeft > 0 || _stunLeft > 0) return;
    _attackCooldown = 0.7;
    onMeleeAttack();
    final delay = meleeAttackDelaySec;
    if (delay <= 0) {
      _dealMeleeDamage(player);
      return;
    }

    game.worldMap.add(
      TimerComponent(
        period: delay,
        repeat: false,
        onTick: () {
          if (_isDead || player.isRemoving || player.hp <= 0) return;
          _dealMeleeDamage(player);
        },
      ),
    );
  }

  void _dealMeleeDamage(PlayerComponent player) {
    player.takeDamage(
      damage,
      attacker: this,
      sourceType: DamageSourceType.melee,
    );
  }

  /// Хук для анимации/визуала удара (по умолчанию пустой).
  void onMeleeAttack() {}

  /// Отталкиваем врага от игрока, чтобы не проходил насквозь.
  void _resolvePlayerOverlap(PlayerComponent player) {
    final dir = position - player.position;
    final dist2 = dir.length2;
    final minDist = (size.x / 2) + (player.size.x / 2);

    if (dist2 == 0) {
      position.add(Vector2(minDist, 0));
      position = game.worldMap.clampToMap(position);
      return;
    }

    final dist = sqrt(dist2);
    final overlap = minDist - dist;
    if (overlap <= 0) return;

    dir.normalize();
    position.add(dir * overlap);
    position = game.worldMap.clampToMap(position);
  }


  void _resolveObstacleCollision(Rect obstacleRect) {
    final enemyRect = _collisionRect();
    if (!enemyRect.overlaps(obstacleRect)) return;

    final enemyCenter = enemyRect.center;
    final obstacleCenter = obstacleRect.center;
    final dx = enemyCenter.dx - obstacleCenter.dx;
    final dy = enemyCenter.dy - obstacleCenter.dy;

    final overlapX = (obstacleRect.width / 2 + enemyRect.width / 2) - dx.abs();
    final overlapY = (obstacleRect.height / 2 + enemyRect.height / 2) - dy.abs();
    if (overlapX <= 0 || overlapY <= 0) return;

    const slop = 2.2;
    final pushXMag = overlapX - slop;
    final pushYMag = overlapY - slop;
    if (pushXMag <= 0 || pushYMag <= 0) return;

    if (overlapX < overlapY) {
      final pushX = (dx == 0) ? pushXMag : dx.sign * pushXMag;
      position.add(Vector2(pushX, 0));
      _setWallFollowDir(dirToPlayer(), axisX: true);
    } else {
      final pushY = (dy == 0) ? pushYMag : dy.sign * pushYMag;
      position.add(Vector2(0, pushY));
      _setWallFollowDir(dirToPlayer(), axisX: false);
    }

    position = game.worldMap.clampToMap(position);

    // Запоминаем направление ухода от препятствия, чтобы обойти его.
    final away = Vector2(dx, dy);
    if (away.length2 > 0.001) {
      away.normalize();
      _avoidDir = away;
      _avoidTimeLeft = 0.35;
    }
  }

  Vector2 dirToPlayer() {
    final p = game.player;
    if (p == null) return Vector2(1, 0);
    final d = (p.position - position);
    if (d.length2 > 0.001) d.normalize();
    return d;
  }

  void _setWallFollowDir(Vector2 desiredDir, {required bool axisX}) {
    // Если упёрлись по X, то двигаться вдоль оси Y; если по Y — вдоль X.
    final a = axisX ? Vector2(0, 1) : Vector2(1, 0);
    final b = axisX ? Vector2(0, -1) : Vector2(-1, 0);
    _wallFollowDir =
        (a.dot(desiredDir) >= b.dot(desiredDir)) ? a : b;
    _wallFollowLeft = 0.9;
  }

  bool _hasLineOfSight(Vector2 from, Vector2 to, List<Rect> rects) {
    for (final r in rects) {
      if (_segmentRectHitT(from, to, r) != null) return false;
    }
    return true;
  }

  double? _segmentRectHitT(Vector2 a, Vector2 b, Rect r) {
    final ax = a.x;
    final ay = a.y;
    final bx = b.x;
    final by = b.y;
    final dx = bx - ax;
    final dy = by - ay;

    double t0 = 0.0;
    double t1 = 1.0;

    bool clip(double p, double q) {
      if (p == 0) return q >= 0;
      final t = q / p;
      if (p < 0) {
        if (t > t1) return false;
        if (t > t0) t0 = t;
      } else {
        if (t < t0) return false;
        if (t < t1) t1 = t;
      }
      return true;
    }

    if (!clip(-dx, ax - r.left)) return null;
    if (!clip(dx, r.right - ax)) return null;
    if (!clip(-dy, ay - r.top)) return null;
    if (!clip(dy, r.bottom - ay)) return null;

    return t0;
  }

  Vector2 _computeObstacleAvoidance(Vector2 desiredDir) {
    final rects = game.worldMap.collisionRects;
    if (rects.isEmpty) return Vector2.zero();

    const avoidRadius = 70.0;
    const lookAhead = 28.0;
    final pos = position;
    var steer = Vector2.zero();
    var touched = false;

    for (final r in rects) {
      final closest = Offset(
        pos.x.clamp(r.left, r.right),
        pos.y.clamp(r.top, r.bottom),
      );
      final dx = pos.x - closest.dx;
      final dy = pos.y - closest.dy;
      final dist2 = dx * dx + dy * dy;
      if (dist2 <= 0.0001) continue;
      final dist = sqrt(dist2);
      if (dist > avoidRadius) continue;
      touched = true;

      final strength = 1.0 - (dist / avoidRadius);
      final away = Vector2(dx / dist, dy / dist) * (strength * 0.8);
      steer += away;
    }

    // Быстрый "взгляд вперёд": если следующая позиция врезается в препятствие —
    // усиливаем уход в сторону.
    final ahead = pos + desiredDir * lookAhead;
    if (touched) {
      for (final r in rects) {
        if (r.contains(Offset(ahead.x, ahead.y))) {
          final perp = Vector2(-desiredDir.y, desiredDir.x) * _stuckTurn.toDouble();
          steer += perp * 0.4;
          break;
        }
      }
    }

    if (!touched) return Vector2.zero();
    if (steer.length2 > 0.001) {
      steer.normalize();
    }

    return steer;
  }

  void _updateStuckState(Vector2 desiredDir, Vector2 avoid, Vector2 playerPos, double dt) {
    if (avoid.length2 < 0.001 && _wallFollowLeft <= 0) {
      _stuckTime = max(0, _stuckTime - dt * 2.0);
      return;
    }

    final moved = position.distanceTo(_lastPos);
    _lastPos.setFrom(position);

    if (moved < 0.8) {
      _stuckTime += dt;
    } else {
      _stuckTime = max(0, _stuckTime - dt * 2.0);
    }

    if (_stuckCooldown <= 0 && _stuckTime > 0.55) {
      _stuckTime = 0.0;
      _stuckCooldown = 0.6;
      _stuckTurn = -_stuckTurn;
      if (_wallFollowLeft > 0) {
        // В углу: разворачиваемся вдоль стены.
        _wallFollowDir = _wallFollowDir * -1;
        _wallFollowLeft = 1.0;
        _cornerTime = 0.6;
      } else {
        _avoidDir = Vector2(-desiredDir.y, desiredDir.x) * _stuckTurn.toDouble();
        _avoidTimeLeft = 0.5;
      }

    }
  }

  Rect _collisionRect() {
    final radius = _hitbox.radius;
    return Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: radius * 2,
      height: radius * 2,
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

    _showHpBar = true;
    var finalDamage = value;
    if (isBoss && attacker is PlayerComponent) {
      final mult = game.runModifiers.bossDamageMultiplier;
      finalDamage = max(1, (finalDamage * mult).round());
    }

    _lastAttacker = attacker;

    if (showHitEffects) {
      game.requestHitStop(isCrit ? 0.016 : 0.012);

      // Вспышка.
      _flashTimer = _flashDuration;

      // Урон над головой.
      game.worldMap.add(
        DamageNumberComponent(
          position: position + Vector2(0, -18),
          value: finalDamage,
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

    _hp -= finalDamage;
    if (_hp > 0) {
      onDamageTaken();
    }
    if (_hp <= 0) _die();
  }

  void _die() {
    if (_isDead) return;
    _isDead = true;

    if (isBoss) {
      game.clearBossHud();
      game.showBossReward();
    }

    _hitbox.collisionType = CollisionType.inactive;
    onDeath();

    game.scoreSystem.addScore(scoreReward);
    if (xpReward > 0) {
      final pieces = _splitXpReward(xpReward, game.rng);
      for (final xp in pieces) {
        final angle = game.rng.nextDouble() * pi * 2;
        final dist = 10 + game.rng.nextDouble() * 30;
        final scatter = Vector2(cos(angle) * dist, sin(angle) * dist);
        final dropPos = game.worldMap.clampToMap(position + scatter);
        game.worldMap.add(
          XpCrystalComponent(
            position: dropPos,
            xp: xp,
          ),
        );
      }
    }

    final killer = _lastAttacker;
    if (killer is PlayerComponent) {
      killer.buffs.emit(
        EnemyKilledEvent(
          killer: killer,
          enemy: this,
        ),
      );
    }

    game.onEnemyKilled(this);

    final delay = deathDespawnDelaySec;
    if (delay <= 0) {
      Future<void>.microtask(() {
        if (!isRemoving) removeFromParent();
      });
      return;
    }

    game.worldMap.add(
      TimerComponent(
        period: delay,
        repeat: false,
        onTick: () {
          if (!isRemoving) removeFromParent();
        },
      ),
    );
  }
}

List<double> _splitXpReward(int total, Random rng) {
  if (total <= 0) return <double>[];

  int targetPieces;
  if (total <= 2) {
    targetPieces = total * 6;
  } else if (total <= 6) {
    targetPieces = total * 5;
  } else if (total <= 12) {
    targetPieces = total * 4;
  } else if (total <= 20) {
    targetPieces = total * 3;
  } else {
    targetPieces = total * 2;
  }

  final jitter = rng.nextInt(5) - 2;
  targetPieces = (targetPieces + jitter).clamp(12, 60);

  final perPiece = total / targetPieces;
  final pieces = List<double>.filled(targetPieces, perPiece);
  pieces.shuffle(rng);
  return pieces;
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
