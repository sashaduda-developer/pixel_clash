import 'dart:math';
import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/interactables/interaction_aura_component.dart';
import 'package:pixel_clash/game/components/interactables/solid_obstacle.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/render/pixel_perfect.dart';

/// Сундук: если игрок рядом N секунд — открывается и выдаёт награду.
///
/// Сейчас награда будет тестовая (позже заменим на LootTable).
class ChestComponent extends PositionComponent
    with HasGameReference<PixelClashGame>, CollisionCallbacks, SolidObstacle {
  ChestComponent({
    required super.position,
    this.openTime = 2.0,
    this.interactRadius = 62,
  });

  static const String _spritePath = 'cemetery/objects/chest.png';

  static final Images _mapImages = Images(prefix: 'assets/maps/');
  static Sprite? _chestSprite;
  static Vector2? _chestSpriteSize;
  InteractionAuraComponent? _aura;

  final double openTime;
  final double interactRadius;

  bool _opened = false;
  double _progress = 0;

  late final RectangleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _ensureSprite();
    size = _chestSpriteSize ?? Vector2.all(48);
    anchor = Anchor.center;

    _buildAura();
    _buildSprite();
    _buildHitbox();
  }

  void _buildAura() {
    final aura = InteractionAuraComponent(
      radius: interactRadius,
      color: const Color(0xFFC28C43),
    )..priority = -1;
    aura.position = size / 2;
    add(aura);
    _aura = aura;
  }

  Future<void> _ensureSprite() async {
    if (_chestSprite != null && _chestSpriteSize != null) return;

    final image = await _mapImages.load(_spritePath);
    _chestSprite ??= Sprite(image);
    _chestSpriteSize ??= Vector2(
      image.width.toDouble(),
      image.height.toDouble(),
    );
  }

  void _buildSprite() {
    final sprite = _chestSprite;
    if (sprite == null) return;

    add(
      SpriteComponent(
        sprite: sprite,
        size: size,
        anchor: Anchor.topLeft,
        position: Vector2.zero(),
        paint: pixelPaint(),
      ),
    );
  }

  void _buildHitbox() {
    final hitboxSize = Vector2(
      max(8.0, size.x - 12),
      max(8.0, size.y - 12),
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
    if (_opened) return;

    final p = game.player;
    if (p == null || p.isRemoving) return;

    final dist2 = p.position.distanceToSquared(position);
    final r2 = interactRadius * interactRadius;

    if (dist2 <= r2) {
      _progress = min(openTime, _progress + dt);
      if (_progress >= openTime) {
        _opened = true;
        _progress = openTime;
        _open();
      }
    } else {
      _progress = max(0, _progress - dt * 1.2);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);


    // Прогресс открытия (кольцо над сундуком)
    if (!_opened && _progress > 0) {
      final t = (_progress / openTime).clamp(0.0, 1.0);

      final center = Offset(size.x / 2, -18);
      const radius = 11.0;

      final bg = Paint()
        ..color = const Color(0x22000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final glow = Paint()
        ..color = const Color(0x55C28C43)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final fg = Paint()
        ..color = const Color(0xFFC28C43)
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

  void _open() {
    // Пока просто сигналим игре: "сундук открыт".
    // Позже здесь будет конкретный loot roll.
    game.onChestOpened();
    _aura?.removeFromParent();
  }
}
