import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

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

    final p = game.player;
    if (p == null || p.isRemoving) return;

    final dir = (p.position - position);
    if (dir.length2 > 0.001) {
      dir.normalize();
      position += dir * speed * dt;
    }
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

    _renderHpBar(canvas);
  }

  /// Рисуем HP бар в локальных координатах врага (над головой).
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
    _attackCooldown = 0.7;
    player.takeDamage(damage);
  }

  @override
  void takeDamage(int value) {
    takeDamageFromHit(value, isCrit: false);
  }

  /// Получение урона с флагом крита (для визуала).
  /// Получение урона с флагом крита (для визуала).
  /// fromChain нужен, чтобы:
  /// 1) не вызывать chain-эффект повторно,
  /// 2) не усиливать визуалы/хитстоп на каждой "прыжковой" молнии,
  /// 3) и главное — чтобы не падало, если кто-то вызывает со старой сигнатурой.
  void takeDamageFromHit(
    int value, {
    required bool isCrit,
  }) {
    if (_isDead) return;

    // hit-stop (легкий, и чуть сильнее на крите)
    // Для chain-ударов хит-стоп лучше не делать (иначе лаги/ступор).
    game.requestHitStop(isCrit ? 0.016 : 0.012);

    // флэш
    _flashTimer = _flashDuration;

    // цифры урона
    game.worldMap.add(
      DamageNumberComponent(
        position: position + Vector2(0, -18),
        value: value,
        color: isCrit ? const Color(0xFFFFD54F) : const Color(0xFFFFF176),
        scaleFactor: isCrit ? 1.35 : 1.0,
      ),
    );

    // искры (на chain меньше, чтобы не забивать кадры)
    spawnHitParticles(
      parent: game.worldMap,
      position: position,
      color: isCrit ? const Color(0xFFFFD54F) : const Color(0xFFFFF176),
      count: isCrit ? 18 : 12,
    );

    // ⚡ молния для крита (только на первом ударе)
    if (isCrit) {
      game.worldMap.add(
        CritLightningComponent(
          position: position + Vector2(0, -10),
        ),
      );
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

    Future<void>.microtask(() {
      if (!isRemoving) removeFromParent();
    });
  }
}
