import 'dart:math';
import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/interactables/interaction_aura_component.dart';
import 'package:pixel_clash/game/components/interactables/solid_obstacle.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/render/pixel_perfect.dart';

/// Алтарь: когда игрок рядом N секунд — выдаёт магическую награду.
class AltarComponent extends PositionComponent
    with HasGameReference<PixelClashGame>, CollisionCallbacks, SolidObstacle {
  AltarComponent({
    required super.position,
    this.openTime = 2.2,
    this.interactRadius = 58,
  });

  static const List<String> _framePaths = <String>[
    'cemetery/objects/altar/altar0.png',
    'cemetery/objects/altar/altar1.png',
    'cemetery/objects/altar/altar2.png',
    'cemetery/objects/altar/altar3.png',
  ];
  static const double _frameStepTime = 0.14;
  static const double _spriteScale = 0.82;
  static const double _hitboxBaseHeight = 48.0;
  static const double _interactAnchorYOffset = 10.0;

  static final Images _mapImages = Images(prefix: 'assets/maps/');
  static SpriteAnimation? _altarAnimation;
  static Vector2? _altarSpriteSize;
  InteractionAuraComponent? _aura;

  final double openTime;
  final double interactRadius;

  bool _activated = false;
  double _progress = 0;

  late final RectangleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _ensureAnimation();
    final baseSize = _altarSpriteSize ?? Vector2(96, 144);
    size = baseSize * _spriteScale;
    anchor = Anchor.center;
    priority = 5;

    _buildAura();
    _buildSprite();
    _buildHitbox();
  }

  void _buildAura() {
    final aura = InteractionAuraComponent(
      radius: interactRadius,
      color: const Color(0xFFE16B6B),
    )..priority = -1;
    aura.position = _interactionAnchor();
    add(aura);
    _aura = aura;
  }

  Future<void> _ensureAnimation() async {
    if (_altarAnimation != null && _altarSpriteSize != null) return;
    final images = await _mapImages.loadAll(_framePaths);
    if (images.isEmpty) return;
    _altarSpriteSize ??= Vector2(
      images.first.width.toDouble(),
      images.first.height.toDouble(),
    );
    final sprites = images.map(Sprite.new).toList();
    _altarAnimation ??= SpriteAnimation.spriteList(
      sprites,
      stepTime: _frameStepTime,
    );
  }

  void _buildSprite() {
    final animation = _altarAnimation;
    if (animation == null) return;
    add(
      SpriteAnimationComponent(
        animation: animation.clone(),
        size: size,
        anchor: Anchor.topLeft,
        position: Vector2.zero(),
        paint: pixelPaint(),
      ),
    );
  }

  void _buildHitbox() {
    final hitboxHeight = max(8.0, min(_hitboxBaseHeight, size.y) - 12);
    final hitboxSize = Vector2(
      max(8.0, size.x - 12),
      hitboxHeight,
    );
    _hitbox = RectangleHitbox(
      size: hitboxSize,
      position: Vector2(
        (size.x - hitboxSize.x) / 2,
        size.y - hitboxSize.y,
      ),
    )..collisionType = CollisionType.passive;
    add(_hitbox);
  }

  @override
  Rect get collisionRect => _hitboxWorldRect();

  Rect _hitboxWorldRect() {
    final topLeft = position + _hitbox.position - (size / 2);
    return Rect.fromLTWH(topLeft.x, topLeft.y, _hitbox.size.x, _hitbox.size.y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_activated) return;

    final p = game.player;
    if (p == null || p.isRemoving) return;

    final dist2 = p.position.distanceToSquared(_interactionCenterWorld());
    final r2 = interactRadius * interactRadius;

    if (dist2 <= r2) {
      _progress = min(openTime, _progress + dt);
      if (_progress >= openTime) {
        _activated = true;
        _progress = openTime;
        _activate();
      }
    } else {
      _progress = max(0, _progress - dt * 1.2);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Прогресс активации (кольцо)
    if (!_activated && _progress > 0) {
      final t = (_progress / openTime).clamp(0.0, 1.0);

      final center = Offset(size.x / 2, -20);
      const radius = 11.0;

      final bg = Paint()
        ..color = const Color(0x22000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final glow = Paint()
        ..color = const Color(0x55E16B6B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final fg = Paint()
        ..color = const Color(0xFFE16B6B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, bg);
      canvas.drawCircle(center, radius, glow);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        pi * 2 * t,
        false,
        fg,
      );
    }
  }

  void _activate() {
    game.onAltarActivated();
    _aura?.removeFromParent();
  }

  Vector2 _interactionAnchor() {
    return Vector2(
      size.x / 2,
      size.y - _hitboxBaseHeight * 0.5 + _interactAnchorYOffset,
    );
  }

  Vector2 _interactionCenterWorld() {
    return position + _interactionAnchor() - (size / 2);
  }
}
