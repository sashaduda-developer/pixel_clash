import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import 'package:pixel_clash/game/components/player/player_component.dart';

class ThreatCard extends PositionComponent with CollisionCallbacks {
  ThreatCard({
    required super.position,
    required this.onPicked,
  });

  final VoidCallback onPicked;

  late final RectangleHitbox _hitbox;

  final Paint _paint = Paint()..color = const Color(0xFFE53935);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2(22, 30);
    anchor = Anchor.center;

    _hitbox = RectangleHitbox(size: size);
    add(_hitbox);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = size.toRect();
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      _paint,
    );

    final skullPaint = Paint()..color = const Color(0xFF000000).withValues(alpha: 0.65);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.42), 5, skullPaint);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.x * 0.5, size.y * 0.62),
        width: 10,
        height: 5,
      ),
      skullPaint,
    );
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerComponent) {
      onPicked();
      removeFromParent();
    }
  }
}
