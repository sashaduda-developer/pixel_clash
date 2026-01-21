import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/damageable.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Снаряд рейнджера.
/// Визуальный тип снаряда (без привязки к логике урона).
enum ProjectileVisual {
  bolt,
  fireball,
}

class ProjectileArrow extends PositionComponent with CollisionCallbacks {
  ProjectileArrow({
    required super.position,
    required Vector2 direction,
    required this.speed,
    required this.damage,
    required this.isCrit,
    required this.owner,
    this.sourceType = DamageSourceType.arrow,
    this.paintColor = const Color(0xFFFFD54F),
    this.sizeOverride,
    this.visual = ProjectileVisual.bolt,
    this.pierceCount = 0,
    this.ricochetBounces = 0,
    this.ricochetDamageMultiplier = 0.7,
    this.maxLifeSeconds = 2.0,
  })  : _direction = direction.normalized(),
        _paint = Paint()..color = paintColor;

  /// Нормализованное направление полета.
  final Vector2 _direction;

  /// Скорость (пикс/сек).
  final double speed;

  /// Урон.
  final int damage;

  final PlayerComponent owner;

  final DamageSourceType sourceType;
  final Color paintColor;
  final Vector2? sizeOverride;
  final ProjectileVisual visual;

  /// Сколько целей может пробить, не исчезая.
  int pierceCount;

  /// Количество рикошетов после попадания.
  int ricochetBounces;

  /// Множитель урона для рикошетов.
  final double ricochetDamageMultiplier;

  /// Время жизни (сек), чтобы не летать бесконечно.
  final double maxLifeSeconds;

  final bool isCrit;

  late final RectangleHitbox _hitbox;

  double _life = 0;

  final Paint _paint;

  final Set<EnemyComponent> _hitEnemies = <EnemyComponent>{};

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = sizeOverride ?? Vector2(18, 4);
    anchor = Anchor.center;

    // Разворачиваем под направление.
    angle = _direction.angleToSigned(Vector2(1, 0));

    _hitbox = RectangleHitbox(size: size);
    add(_hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (owner.game.isRewardPauseActive) return;
    _life += dt;
    if (_life >= maxLifeSeconds) {
      removeFromParent();
      return;
    }

    position += _direction * speed * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    switch (visual) {
      case ProjectileVisual.bolt:
        final rect = Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2),
          width: size.x,
          height: size.y,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          _paint,
        );
        break;
      case ProjectileVisual.fireball:
        final center = Offset(size.x / 2, size.y / 2);
        final radius = (size.x.clamp(6.0, 30.0)) / 2;
        final core = Paint()..color = paintColor.withValues(alpha: 0.95);
        final glow = Paint()..color = paintColor.withValues(alpha: 0.35);
        canvas.drawCircle(center, radius * 1.35, glow);
        canvas.drawCircle(center, radius, core);
        break;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is! Damageable) return;

    if (other is EnemyComponent) {
      if (_hitEnemies.contains(other)) return;
      _hitEnemies.add(other);

      other.takeDamageFromHit(
        damage,
        isCrit: isCrit,
        attacker: owner,
        sourceType: sourceType,
      );

      owner.buffs.emit(
        DamageDealtEvent(
          attacker: owner,
          target: other,
          amount: damage,
          isCrit: isCrit,
          sourceType: sourceType,
        ),
      );

      // Рикошет в ближайшую цель.
      if (ricochetBounces > 0) {
        final next = owner.game.findNearestEnemyInRadius(
          other.position,
          220,
          exclude: _hitEnemies,
        );
        if (next != null) {
          final dir = (next.position - other.position);
          if (dir.length2 > 0.0001) {
            owner.game.worldMap.add(
              ProjectileArrow(
                owner: owner,
                position: other.position.clone(),
                direction: dir,
                speed: speed,
                damage: (damage * ricochetDamageMultiplier).round().clamp(1, 999999),
                isCrit: false,
                sourceType: sourceType,
                paintColor: paintColor,
                sizeOverride: sizeOverride,
                visual: visual,
                pierceCount: pierceCount,
                ricochetBounces: ricochetBounces - 1,
                ricochetDamageMultiplier: ricochetDamageMultiplier,
              ),
            );
          }
        }
      }

      // Пробитие: если есть стеки — продолжаем лететь.
      if (pierceCount > 0) {
        pierceCount -= 1;
        return;
      }

      removeFromParent();
      return;
    }

    // Прочие Damageable.
    final target = other as Damageable;
    if (!target.isDead) {
      target.takeDamage(damage);
      removeFromParent();
    }
  }
}
