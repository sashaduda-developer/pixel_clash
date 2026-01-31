import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/render/pixel_perfect.dart';

/// Сундук: если игрок рядом N секунд — открывается и выдаёт награду.
///
/// Сейчас награда будет тестовая (позже заменим на LootTable).
class ChestComponent extends PositionComponent
    with HasGameReference<PixelClashGame>, CollisionCallbacks {
  ChestComponent({
    required super.position,
    this.openTime = 2.0,
    this.interactRadius = 54,
  });

  static const double _tileSize = 48;
  static const int _tilesetColumns = 7;
  static const String _tilesetPath = 'tiles/Cemetery_Objects.png';
  static const int _coffinTopTileId = 21;
  static const int _coffinBottomTileId = 28;

  static final Images _mapImages = Images(prefix: 'assets/maps/');
  static Sprite? _coffinTopSprite;
  static Sprite? _coffinBottomSprite;

  final double openTime;
  final double interactRadius;

  bool _opened = false;
  double _progress = 0;

  late final RectangleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(_tileSize, _tileSize * 2);
    anchor = Anchor.center;

    await _ensureSprites();
    _buildSprites();
    _buildHitbox();
  }

  Future<void> _ensureSprites() async {
    if (_coffinTopSprite != null && _coffinBottomSprite != null) return;

    final image = await _mapImages.load(_tilesetPath);
    _coffinTopSprite ??= _spriteFromTile(image, _coffinTopTileId);
    _coffinBottomSprite ??= _spriteFromTile(image, _coffinBottomTileId);
  }

  Sprite _spriteFromTile(ui.Image image, int tileId) {
    final col = tileId % _tilesetColumns;
    final row = tileId ~/ _tilesetColumns;
    final src = Vector2(col * _tileSize, row * _tileSize);
    return Sprite(
      image,
      srcPosition: src,
      srcSize: Vector2.all(_tileSize),
    );
  }

  void _buildSprites() {
    final top = _coffinTopSprite;
    final bottom = _coffinBottomSprite;
    if (top == null || bottom == null) return;

    add(
      SpriteComponent(
        sprite: top,
        size: Vector2(_tileSize, _tileSize),
        anchor: Anchor.topLeft,
        position: Vector2.zero(),
        paint: pixelPaint(),
      ),
    );

    add(
      SpriteComponent(
        sprite: bottom,
        size: Vector2(_tileSize, _tileSize),
        anchor: Anchor.topLeft,
        position: Vector2(0, _tileSize),
        paint: pixelPaint(),
      ),
    );
  }

  void _buildHitbox() {
    final hitboxSize = Vector2(_tileSize - 12, _tileSize - 12);
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

      final center = Offset(size.x / 2, -10);
      const radius = 10.0;

      final bg = Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final fg = Paint()
        ..color = const Color(0xFF66BB6A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, bg);

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
    removeFromParent();
  }
}
