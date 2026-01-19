import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';

import 'package:pixel_clash/game/components/combat/damageable.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Стрела рейнджера (без наведения).
/// Летит по прямой и наносит урон первому объекту, который реализует Damageable.
class ProjectileArrow extends PositionComponent with CollisionCallbacks {
  ProjectileArrow({
    required super.position,
    required Vector2 direction,
    required this.speed,
    required this.damage,
    required this.isCrit,
    required this.owner,
    this.maxLifeSeconds = 2.0,
  }) : _direction = direction.normalized();

  /// Нормализованное направление полёта.
  final Vector2 _direction;

  /// Скорость полёта (пикс/сек).
  final double speed;

  /// Урон.
  final int damage;

  final PlayerComponent owner;

  /// Время жизни, чтобы стрела не летала бесконечно.
  final double maxLifeSeconds;

  final bool isCrit;

  late final RectangleHitbox _hitbox;

  double _life = 0;

  final Paint _paint = Paint()..color = const Color(0xFFFFD54F);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Визуально это маленький прямоугольник.
    size = Vector2(18, 4);
    anchor = Anchor.center;

    // Повернём стрелу в сторону полёта.
    angle = _direction.angleToSigned(Vector2(1, 0));

    _hitbox = RectangleHitbox(size: size);
    add(_hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);

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

    final rect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x,
      height: size.y,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      _paint,
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Стрела не должна бить игрока (если вдруг будет коллизия).
    // Если у тебя уже есть отдельная логика "friend/foe" — можно убрать.
    if (other is! Damageable) return;

    // Если это враг — прокидываем crit во врага для красивого эффекта.
    if (other is EnemyComponent) {
      other.takeDamageFromHit(damage, isCrit: isCrit);
      owner.buffs.emit(
        DamageDealtEvent(
          attacker: owner,
          target: other,
          amount: damage,
          isCrit: isCrit,
          sourceType: DamageSourceType.arrow,
        ),
      );
      removeFromParent();
      return;
    }

    // Любой другой Damageable (на будущее: объекты/бочки/тотемы).
    final target = other as Damageable;
    if (!target.isDead) {
      target.takeDamage(damage);
      removeFromParent();
    }
  }
}
