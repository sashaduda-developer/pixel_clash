import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/buff_system.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar_buffs.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/melee_swing.dart';
import 'package:pixel_clash/game/components/combat/projectile_arrow.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/attack_profile.dart';
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
  })  : stats = PlayerStats.forHero(heroType),
        attackProfile = AttackProfile.forHero(heroType);

  final HeroType heroType;
  final PlayerStats stats;
  final AttackProfile attackProfile;

  int get hp => stats.hp;
  int get maxHp => stats.maxHp;

  late final CircleHitbox _hitbox;
  late final BuffSystem buffs;

  bool _isDead = false;

  final Color _baseColorRanger = const Color(0xFF42A5F5);
  final Color _baseColorKnight = const Color(0xFF66BB6A);
  final Color _baseColorMage = const Color(0xFF26C6DA);
  final Color _baseColorNinja = const Color(0xFFEF5350);
  final Color _flashColor = const Color(0xFFFFFFFF);

  double _flashTimer = 0;
  static const double _flashDuration = 0.08;

  double _attackTimer = 0;
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

    // Апдейт баффов после перемещения и атаки.
    buffs.update(dt);
    _updateMana(dt);
  }

  void _autoAttack() {
    switch (attackProfile.style) {
      case AttackStyle.ranger:
        _rangerAttack();
        break;
      case AttackStyle.knight:
        _knightAttack();
        break;
      case AttackStyle.mage:
        _mageAttack();
        break;
      case AttackStyle.ninja:
        _ninjaAttack();
        break;
    }
  }

  /// Роллим урон и флаг крита.
  (int, bool) _rollDamage() {
    final r = game.rng.nextDouble();
    final isCrit = r < stats.critChance;

    final base = stats.damage;
    final dmg = isCrit ? (base * stats.critMultiplier).round() : base;

    return (dmg, isCrit);
  }

  EnemyComponent? _findNearestEnemyInRange({
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

  void _rangerAttack() {
    final target = _findNearestEnemyInRange(
      onlyVisibleOnScreen: true,
      range: attackProfile.range,
    );
    if (target == null) return;

    final dir = (target.position - position);
    if (dir.length2 <= 0.0001) return;

    final (dmg, isCrit) = _rollDamage();

    _shootProjectile(
      direction: dir,
      damage: dmg,
      isCrit: isCrit,
      speed: attackProfile.projectileSpeed,
      color: attackProfile.projectileColor,
      size: attackProfile.projectileSize,
      sourceType: DamageSourceType.arrow,
    );
  }

  void _mageAttack() {
    final target = _findNearestEnemyInRange(
      onlyVisibleOnScreen: true,
      range: attackProfile.range,
    );
    if (target == null) return;

    final dir = (target.position - position);
    if (dir.length2 <= 0.0001) return;

    final (dmg, isCrit) = _rollDamage();

    _shootProjectile(
      direction: dir,
      damage: dmg,
      isCrit: isCrit,
      speed: attackProfile.projectileSpeed,
      color: attackProfile.projectileColor,
      size: attackProfile.projectileSize,
      sourceType: DamageSourceType.ability,
      visual: ProjectileVisual.fireball,
    );
  }

  void _knightAttack() {
    final target = _findNearestEnemyInRange(
      onlyVisibleOnScreen: false,
      range: attackProfile.range,
    );
    if (target == null) return;

    final (dmg, isCrit) = _rollDamage();
    _spawnMeleeSwing(
      radius: attackProfile.meleeRadius,
      damage: dmg,
      isCrit: isCrit,
      color: const Color(0xFF81C784),
      maxAlpha: 0.45,
    );

    final dir = (target.position - position);
    if (dir.length2 <= 0.0001) return;

    final waveDamage = (dmg * attackProfile.waveDamageMultiplier).round().clamp(1, 999999);
    _shootProjectile(
      direction: dir,
      damage: waveDamage,
      isCrit: false,
      speed: attackProfile.projectileSpeed,
      color: attackProfile.projectileColor,
      size: attackProfile.projectileSize,
      sourceType: DamageSourceType.melee,
    );
  }

  void _ninjaAttack() {
    final target = _findNearestEnemyInRange(
      onlyVisibleOnScreen: false,
      range: attackProfile.range,
    );
    if (target == null) return;

    final (dmg, isCrit) = _rollDamage();
    _spawnMeleeSwing(
      radius: attackProfile.meleeRadius,
      damage: dmg,
      isCrit: isCrit,
      color: const Color(0xFFEF5350),
      maxAlpha: 0.55,
    );

    if (attackProfile.ninjaHits <= 1) return;

    game.worldMap.add(
      TimerComponent(
        period: attackProfile.ninjaHitDelaySec,
        repeat: false,
        onTick: () {
          _spawnMeleeSwing(
            radius: attackProfile.meleeRadius * 0.9,
            damage: (dmg * 0.8).round().clamp(1, 999999),
            isCrit: false,
            color: const Color(0xFFFF7043),
            maxAlpha: 0.5,
          );
        },
      ),
    );
  }

  void _spawnMeleeSwing({
    required double radius,
    required int damage,
    required bool isCrit,
    Color color = const Color(0xFF90CAF9),
    double maxAlpha = 0.32,
    bool drawOutline = true,
  }) {
    final swing = MeleeSwing(
      owner: this,
      position: position.clone(),
      radius: radius,
      damage: damage,
      isCrit: isCrit,
      color: color,
      maxAlpha: maxAlpha,
      drawOutline: drawOutline,
    );

    game.worldMap.add(swing);
  }

  void _shootProjectile({
    required Vector2 direction,
    required int damage,
    required bool isCrit,
    required double speed,
    required Color color,
    required Size size,
    required DamageSourceType sourceType,
    ProjectileVisual visual = ProjectileVisual.bolt,
  }) {
    final (pierceCount, ricochetBounces, ricochetMultiplier) = _projectileModifiers();

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
      pierceCount: pierceCount,
      ricochetBounces: ricochetBounces,
      ricochetDamageMultiplier: ricochetMultiplier,
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

  void _updateMana(double dt) {
    if (stats.regenMana(dt)) {
      game.notifyPlayerStatsChanged();
    }
  }

  @override
  void render(Canvas canvas) {
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

  void takeDamage(
    int rawDamage, {
    PositionComponent? attacker,
    DamageSourceType sourceType = DamageSourceType.unknown,
  }) {
    if (_isDead) return;

    // Шанс уклониться от удара.
    final evade = stats.evasionChance.clamp(0.0, 0.80);
    if (evade > 0 && game.rng.nextDouble() < evade) {
      // Визуальный фидбек уклонения.
      game.worldMap.add(
        DamageNumberComponent(
          position: position + Vector2(0, -24),
          value: 0,
          label: 'MISS',
          color: const Color(0xFFB0BEC5),
          scaleFactor: 0.95,
        ),
      );
      return;
    }

    final dmg = max(1, rawDamage - stats.armor);

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

    Future<void>.microtask(() {
      if (!isRemoving) removeFromParent();
    });

    game.onPlayerDied();
  }

  Color _heroBaseColor() {
    switch (heroType) {
      case HeroType.ranger:
        return _baseColorRanger;
      case HeroType.knight:
        return _baseColorKnight;
      case HeroType.mage:
        return _baseColorMage;
      case HeroType.ninja:
        return _baseColorNinja;
    }
  }
}
