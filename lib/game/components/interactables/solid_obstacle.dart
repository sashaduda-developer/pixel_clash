import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Shared interface for static obstacles with collision bounds.
mixin SolidObstacle on PositionComponent {
  /// Collision bounds in world coordinates.
  Rect get collisionRect;
}

/// Marker for obstacles that block movement but let projectiles pass.
mixin ProjectilePassThrough on PositionComponent {}
