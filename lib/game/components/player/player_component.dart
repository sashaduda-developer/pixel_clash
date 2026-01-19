import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/buff_system.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';

import 'package:pixel_clash/game/components/combat/melee_swing.dart';
import 'package:pixel_clash/game/components/combat/projectile_arrow.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/hero_type.dart';
import 'package:pixel_clash/game/components/player/player_stats.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/ui/damage_number_component.dart';
import 'package:pixel_clash/game/ui/hit_particles.dart';

class PlayerComponent extends PositionComponent
    with HasGameReference<PixelClashGame>, CollisionCallbacks {
  PlayerComponent({
    required this.heroType,
    required super.position,
  }) : stats = PlayerStats.forHero(heroType);

  final HeroType heroType;
  final PlayerStats stats;

  int get hp => stats.hp;
  int get maxHp => stats.maxHp;

  late final CircleHitbox _hitbox;
  late final BuffSystem buffs;

  bool _isDead = false;

  final Color _baseColorRanger = const Color(0xFF42A5F5);
  final Color _baseColorKnight = const Color(0xFF66BB6A);
  final Color _flashColor = const Color(0xFFFFFFFF);

  double _flashTimer = 0;
  static const double _flashDuration = 0.08;

  double _attackTimer = 0;
  final double _attackRange = 420;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2.all(32);
    anchor = Anchor.center;

    _hitbox = CircleHitbox(radius: 14);
    add(_hitbox);

    game.notifyPlayerStatsChanged();
    buffs = BuffSystem(this);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDead) return;

    _flashTimer = max(0, _flashTimer - dt);

    final dir = game.joystick.relativeDelta.clone();
    if (dir.length2 > 0) {
      dir.normalize();
      position += dir * stats.moveSpeed * dt;
      position = game.worldMap.clampToMap(position);
    }

    _attackTimer += dt;
    final interval = (1.0 / stats.attackSpeed).clamp(0.12, 10.0);
    if (_attackTimer >= interval) {
      _attackTimer = 0;
      _autoAttack();
    }
  }

  void _autoAttack() {
    if (heroType == HeroType.ranger) {
      final target = _findNearestEnemyInRange(onlyVisibleOnScreen: true);
      if (target == null) return;
      _shootArrow(target);
      return;
    }

    final target = _findNearestEnemyInRange(onlyVisibleOnScreen: false);
    if (target == null) return;
    _meleeHit();
  }

  /// Считает урон с учётом крита.
  /// Возвращает (damage, isCrit).
  (int, bool) _rollDamage() {
    final r = game.rng.nextDouble();
    final isCrit = r < stats.critChance;

    final base = stats.damage;
    final dmg = isCrit ? (base * stats.critMultiplier).round() : base;

    return (dmg, isCrit);
  }

  EnemyComponent? _findNearestEnemyInRange({required bool onlyVisibleOnScreen}) {
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
      if (d2 > _attackRange * _attackRange) continue;

      if (d2 < bestDist2) {
        bestDist2 = d2;
        best = c;
      }
    }

    return best;
  }

  void _shootArrow(EnemyComponent target) {
    final dir = (target.position - position);
    if (dir.length2 <= 0.0001) return;

    final (dmg, isCrit) = _rollDamage();

    final arrow = ProjectileArrow(
      owner: this,
      position: position.clone(),
      direction: dir,
      speed: 520,
      damage: dmg,
      isCrit: isCrit,
    );

    game.worldMap.add(arrow);
  }

  void _meleeHit() {
    final (dmg, isCrit) = _rollDamage();

    final swing = MeleeSwing(
      owner: this,
      position: position.clone(),
      radius: 46,
      damage: dmg,
      isCrit: isCrit,
    );

    game.worldMap.add(swing);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final base = heroType == HeroType.ranger ? _baseColorRanger : _baseColorKnight;
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

  void takeDamage(int rawDamage) {
    if (_isDead) return;

    final dmg = max(1, rawDamage - stats.armor);

    buffs.emit(
      DamageTakenEvent(
        victim: this,
        attacker: null, // пока не знаем кто бьёт (позже добавим)
        amount: dmg,
        sourceType: DamageSourceType.unknown,
      ),
    );

    stats.hp -= dmg;

    // hit-stop (чуть сильнее)
    game.requestHitStop(0.018);

    // флэш
    _flashTimer = _flashDuration;

    // цифры урона
    game.worldMap.add(
      DamageNumberComponent(
        position: position + Vector2(0, -22),
        value: dmg,
        color: const Color(0xFFFF5252),
      ),
    );

    // 🔥 ИСКРЫ
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

    Future<void>.microtask(() {
      if (!isRemoving) removeFromParent();
    });

    game.onPlayerDied();
  }
}
