import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';

import 'package:pixel_clash/game/components/combat/damageable.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Ближний удар рыцаря.
/// Это временный AoE-хитбокс на короткое время.
/// Он появляется вокруг игрока и бьёт всех Damageable, кого заденет.
class MeleeSwing extends PositionComponent with CollisionCallbacks {
  MeleeSwing({
    required super.position,
    required this.radius,
    required this.damage,
    required this.isCrit,
    required this.owner,
    this.lifeSeconds = 0.12,
  });

  /// Радиус удара.
  final double radius;

  /// Урон.
  final int damage;

  final PlayerComponent owner;

  /// Время жизни эффекта удара (сек).
  final double lifeSeconds;

  late final CircleHitbox _hitbox;

  final bool isCrit;

  double _life = 0;

  final Paint _basePaint = Paint()..color = const Color(0xFF90CAF9);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2.all(radius * 2);
    anchor = Anchor.center;

    _hitbox = CircleHitbox(radius: radius)..collisionType = CollisionType.active;
    add(_hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _life += dt;
    if (_life >= lifeSeconds) {
      removeFromParent();
      return;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Плавное затухание (alpha уменьшается со временем)
    final t = (1 - (_life / lifeSeconds)).clamp(0.0, 1.0);
    final paint = Paint()..color = _basePaint.color.withValues(alpha: 0.25 * t);

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      radius,
      paint,
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is! Damageable) return;

    // Для мили мы обычно хотим ударить и исчезнуть (как у тебя сейчас).
    // Если в будущем надо бить нескольких — уберём removeFromParent().
    if (other is EnemyComponent) {
      other.takeDamageFromHit(damage, isCrit: isCrit);
      owner.buffs.emit(
        DamageDealtEvent(
          attacker: owner,
          target: other,
          amount: damage,
          isCrit: isCrit,
          sourceType: DamageSourceType.melee,
        ),
      );

      removeFromParent();
      return;
    }

    final target = other as Damageable;
    if (!target.isDead) {
      target.takeDamage(damage);
      removeFromParent();
    }
  }
}
