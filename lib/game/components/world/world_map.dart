import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/config/game_constants.dart';
import 'package:pixel_clash/game/render/pixel_perfect.dart';

/// Мир/карта.
/// В 0.1 используем Tiled + простой фон-фоллбек.
class WorldMap extends World {
  final Vector2 mapSize = Vector2(GameConstants.mapWidth, GameConstants.mapHeight);
  static const String tiledMapFile = 'cemetery.tmx';
  static const String tiledMapPrefix = 'assets/maps/';
  static final Images _tiledImages = Images(prefix: tiledMapPrefix);
  static final Vector2 tileSize = Vector2(48, 48);
  static const String layerGround = 'ground';
  static const String layerDecals = 'decals';
  static const String layerObjects = 'objects';
  static const String layerCollisions = 'collisions';
  static const bool _debugDrawCollisions = false;

  TiledComponent? _tiled;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(_MapBackground(size: mapSize));

    _tiled = await _loadTiledMap();
    final tiled = _tiled;
    if (tiled != null) {
      add(tiled);
      _spawnCollidersFromLayer(layerCollisions);
    }
  }

  /// РћРіСЂР°РЅРёС‡РµРЅРёРµ РїРѕР·РёС†РёРё РІРЅСѓС‚СЂРё РєР°СЂС‚С‹.
  Vector2 clampToMap(Vector2 p) {
    final x = p.x.clamp(32.0, mapSize.x - 32.0);
    final y = p.y.clamp(32.0, mapSize.y - 32.0);
    return Vector2(x, y);
  }

  List<TiledObject> objectsFromLayer(String layerName) {
    final tiled = _tiled;
    if (tiled == null) return const <TiledObject>[];

    final group = tiled.tileMap.getLayer<ObjectGroup>(layerName);
    if (group == null) return const <TiledObject>[];

    return List<TiledObject>.from(group.objects);
  }

  ({String tilesetName, int localId})? gidInfo(int gid) {
    final tiled = _tiled;
    if (tiled == null) return null;
    if (gid <= 0) return null;

    final cleanGid = _clearGidFlags(gid);
    final tileset = tiled.tileMap.map.tilesetByTileGId(cleanGid);
    final firstGid = tileset.firstGid ?? 0;
    return (
      tilesetName: tileset.name ?? '',
      localId: cleanGid - firstGid,
    );
  }

  int _clearGidFlags(int gid) => gid & 0x1FFFFFFF;

  Future<TiledComponent?> _loadTiledMap() async {
    try {
      final tiled = await TiledComponent.load(
        tiledMapFile,
        tileSize,
        prefix: tiledMapPrefix,
        images: _tiledImages,
        layerPaintFactory: (opacity) => pixelPaint(opacity: opacity),
        useAtlas: false,
      );
      tiled.position = Vector2.zero();
      tiled.anchor = Anchor.topLeft;
      return tiled;
    } catch (e) {
      debugPrint('WorldMap: failed to load $tiledMapFile ($e)');
      return null;
    }
  }

  void _spawnCollidersFromLayer(String layerName) {
    final tiled = _tiled;
    if (tiled == null) return;

    final group = tiled.tileMap.getLayer<ObjectGroup>(layerName);
    if (group == null) return;

    for (final obj in group.objects) {
      if (!obj.visible) continue;
      if (obj.isPoint || obj.isPolygon || obj.isPolyline) continue;

      final size = Vector2(obj.width, obj.height);
      if (size.x <= 0 || size.y <= 0) continue;

      add(
        _TiledCollisionBlock(
          position: Vector2(obj.x, obj.y),
          size: size,
          isEllipse: obj.isEllipse,
          debugDraw: _debugDrawCollisions,
        ),
      );
    }
  }
}

/// Р¤РѕРЅ РєР°СЂС‚С‹ (РІСЂРµРјРµРЅРЅРѕ).
class _MapBackground extends PositionComponent {
  _MapBackground({required Vector2 size}) {
    this.size = size;
    position = Vector2.zero();
    anchor = Anchor.topLeft;
  }

  final _paintFill = Paint()..color = const Color(0xFF1A1A1A);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), _paintFill);
  }
}

class _TiledCollisionBlock extends PositionComponent with CollisionCallbacks {
  _TiledCollisionBlock({
    required Vector2 position,
    required Vector2 size,
    required this.isEllipse,
    required this.debugDraw,
  }) {
    this.position = position;
    this.size = size;
    anchor = Anchor.topLeft;
  }

  final bool isEllipse;
  final bool debugDraw;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final ShapeHitbox hitbox;
    if (isEllipse && size.x == size.y) {
      hitbox = CircleHitbox(
        radius: size.x / 2,
        position: Vector2(size.x / 2, size.y / 2),
      );
    } else {
      hitbox = RectangleHitbox(size: size);
    }

    hitbox.collisionType = CollisionType.active;
    add(hitbox);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!debugDraw) return;

    final paint = Paint()
      ..color = const Color(0x66FF5252)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (isEllipse && size.x == size.y) {
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
      return;
    }

    canvas.drawRect(size.toRect(), paint);
  }
}
