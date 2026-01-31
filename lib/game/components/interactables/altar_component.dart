import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/render/pixel_perfect.dart';

/// Алтарь: когда игрок рядом N секунд — выдаёт магическую награду.
class AltarComponent extends PositionComponent
    with HasGameReference<PixelClashGame>, CollisionCallbacks {
  AltarComponent({
    required super.position,
    this.openTime = 2.2,
    this.interactRadius = 58,
  });

  static const double _tileSize = 48;
  static const int _tilesetColumns = 7;
  static const String _tilesetPath = 'tiles/Cemetery_Objects.png';
  static const int _churchTopLeftTileId = 42;
  static const int _churchTopRightTileId = 43;
  static const int _churchBottomLeftTileId = 49;
  static const int _churchBottomRightTileId = 50;

  static const String _wispPath = 'tiles/Wisp.png';
  static const int _wispFrames = 15;
  static const int _wispFramesPerRow = 3;
  static const double _wispStepTime = 0.12;
  static final Vector2 _wispFrameSize = Vector2(32, 48);

  static final Images _mapImages = Images(prefix: 'assets/maps/');
  static Sprite? _churchTopLeftSprite;
  static Sprite? _churchTopRightSprite;
  static Sprite? _churchBottomLeftSprite;
  static Sprite? _churchBottomRightSprite;
  static SpriteAnimation? _wispAnimation;

  final double openTime;
  final double interactRadius;

  bool _activated = false;
  double _progress = 0;

  late final RectangleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(_tileSize * 2, _tileSize * 2);
    anchor = Anchor.center;

    await _ensureSprites();
    await _ensureWispAnimation();
    _buildSprites();
    _buildWisps();
    _buildHitbox();
  }

  Future<void> _ensureSprites() async {
    if (_churchTopLeftSprite != null &&
        _churchTopRightSprite != null &&
        _churchBottomLeftSprite != null &&
        _churchBottomRightSprite != null) {
      return;
    }

    final image = await _mapImages.load(_tilesetPath);
    _churchTopLeftSprite ??= _spriteFromTile(image, _churchTopLeftTileId);
    _churchTopRightSprite ??= _spriteFromTile(image, _churchTopRightTileId);
    _churchBottomLeftSprite ??= _spriteFromTile(image, _churchBottomLeftTileId);
    _churchBottomRightSprite ??= _spriteFromTile(image, _churchBottomRightTileId);
  }

  Future<void> _ensureWispAnimation() async {
    if (_wispAnimation != null) return;
    final image = await _mapImages.load(_wispPath);
    _wispAnimation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: _wispFrames,
        stepTime: _wispStepTime,
        textureSize: _wispFrameSize,
        amountPerRow: _wispFramesPerRow,
      ),
    );
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
    final tl = _churchTopLeftSprite;
    final tr = _churchTopRightSprite;
    final bl = _churchBottomLeftSprite;
    final br = _churchBottomRightSprite;
    if (tl == null || tr == null || bl == null || br == null) return;

    add(
      SpriteComponent(
        sprite: tl,
        size: Vector2(_tileSize, _tileSize),
        anchor: Anchor.topLeft,
        position: Vector2.zero(),
        paint: pixelPaint(),
      ),
    );
    add(
      SpriteComponent(
        sprite: tr,
        size: Vector2(_tileSize, _tileSize),
        anchor: Anchor.topLeft,
        position: Vector2(_tileSize, 0),
        paint: pixelPaint(),
      ),
    );
    add(
      SpriteComponent(
        sprite: bl,
        size: Vector2(_tileSize, _tileSize),
        anchor: Anchor.topLeft,
        position: Vector2(0, _tileSize),
        paint: pixelPaint(),
      ),
    );
    add(
      SpriteComponent(
        sprite: br,
        size: Vector2(_tileSize, _tileSize),
        anchor: Anchor.topLeft,
        position: Vector2(_tileSize, _tileSize),
        paint: pixelPaint(),
      ),
    );
  }

  void _buildWisps() {
    final baseAnimation = _wispAnimation;
    if (baseAnimation == null) return;

    const wispOffsetY = 2.0;
    const leftX = 0.0;
    final rightX = size.x;
    final y = size.y - wispOffsetY;

    add(
      SpriteAnimationComponent(
        animation: baseAnimation.clone(),
        size: _wispFrameSize,
        anchor: Anchor.bottomCenter,
        position: Vector2(leftX, y),
        paint: pixelPaint(),
      ),
    );
    add(
      SpriteAnimationComponent(
        animation: baseAnimation.clone(),
        size: _wispFrameSize,
        anchor: Anchor.bottomCenter,
        position: Vector2(rightX, y),
        paint: pixelPaint(),
      ),
    );
  }

  void _buildHitbox() {
    final hitboxSize = Vector2(size.x - 12, _tileSize - 12);
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
    if (_activated) return;

    final p = game.player;
    if (p == null || p.isRemoving) return;

    final dist2 = p.position.distanceToSquared(position);
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

      final center = Offset(size.x / 2, -12);
      const radius = 10.0;

      final bg = Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final fg = Paint()
        ..color = const Color(0xFF9FA8DA)
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

  void _activate() {
    game.onAltarActivated();
    removeFromParent();
  }
}
