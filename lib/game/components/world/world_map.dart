import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/interactables/solid_obstacle.dart';
import 'package:pixel_clash/game/config/game_constants.dart';
import 'package:pixel_clash/game/render/pixel_perfect.dart';

/// Мир/карта.
/// В 0.1 используем Tiled + простой фон-фоллбек.
class WorldMap extends World {
  final Vector2 mapSize = Vector2(GameConstants.mapWidth, GameConstants.mapHeight);
  static const String tiledMapFile = 'cemetery.tmx';
  static const String tiledMapPrefix = 'assets/maps/cemetery/';
  static final Images _tiledImages = Images(prefix: tiledMapPrefix);
  static final Vector2 tileSize = Vector2(48, 48);
  static const String layerGround = 'ground';
  static const String layerDecals = 'decals';
  static const String layerObjects = 'objects';
  static const String layerCollisions = 'collisions';
  static const String layerCollisionsHole = 'collisions_hole';
  static const bool _debugDrawCollisions = false;

  TiledComponent? _tiled;
  final List<Rect> _collisionRects = <Rect>[];
  late final int _gridWidth;
  late final int _gridHeight;
  List<bool> _navBlocked = <bool>[];

  List<Rect> get collisionRects => _collisionRects;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(_MapBackground(size: mapSize));
    _gridWidth = (mapSize.x / tileSize.x).floor();
    _gridHeight = (mapSize.y / tileSize.y).floor();

    _tiled = await _loadTiledMap();
    final tiled = _tiled;
    if (tiled != null) {
      add(tiled);
      _collisionRects.clear();
      _spawnCollidersFromLayer(layerCollisions);
      _spawnCollidersFromLayer(layerCollisionsHole, blocksProjectiles: false);
      _buildNavGrid();
    }
  }

  Vector2 clampToMap(Vector2 p) {
    final x = p.x.clamp(32.0, mapSize.x - 32.0);
    final y = p.y.clamp(32.0, mapSize.y - 32.0);
    return Vector2(x, y);
  }

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

  void _spawnCollidersFromLayer(String layerName, {bool blocksProjectiles = true}) {
    final tiled = _tiled;
    if (tiled == null) return;

    final group = tiled.tileMap.getLayer<ObjectGroup>(layerName);
    if (group == null) return;

    for (final obj in group.objects) {
      if (!obj.visible) continue;
      if (obj.isPoint || obj.isPolygon || obj.isPolyline) continue;

      final size = Vector2(obj.width, obj.height);
      if (size.x <= 0 || size.y <= 0) continue;

      _collisionRects.add(Rect.fromLTWH(obj.x, obj.y, size.x, size.y));
      add(
        blocksProjectiles
            ? _TiledCollisionBlock(
                position: Vector2(obj.x, obj.y),
                size: size,
                isEllipse: obj.isEllipse,
                debugDraw: _debugDrawCollisions,
              )
            : _TiledHoleBlock(
                position: Vector2(obj.x, obj.y),
                size: size,
                isEllipse: obj.isEllipse,
                debugDraw: _debugDrawCollisions,
              ),
      );
    }
  }

  void _buildNavGrid() {
    _navBlocked = List<bool>.filled(_gridWidth * _gridHeight, false);
    if (_collisionRects.isEmpty) return;

    for (var y = 0; y < _gridHeight; y++) {
      for (var x = 0; x < _gridWidth; x++) {
        final cellRect = Rect.fromLTWH(
          x * tileSize.x,
          y * tileSize.y,
          tileSize.x,
          tileSize.y,
        );
        for (final r in _collisionRects) {
          if (cellRect.overlaps(r)) {
            _navBlocked[y * _gridWidth + x] = true;
            break;
          }
        }
      }
    }
  }

  bool isCellWalkable(int gx, int gy) {
    if (gx < 0 || gy < 0 || gx >= _gridWidth || gy >= _gridHeight) return false;
    return !_navBlocked[gy * _gridWidth + gx];
  }

  Vector2 gridToWorldCenter(int gx, int gy) {
    return Vector2(
      gx * tileSize.x + tileSize.x / 2,
      gy * tileSize.y + tileSize.y / 2,
    );
  }

  (int, int) _worldToGrid(Vector2 p) {
    final gx = (p.x / tileSize.x).floor().clamp(0, _gridWidth - 1);
    final gy = (p.y / tileSize.y).floor().clamp(0, _gridHeight - 1);
    return (gx, gy);
  }

  List<Vector2> findPath(Vector2 from, Vector2 to) {
    if (_navBlocked.isEmpty) return <Vector2>[];

    var (sx, sy) = _worldToGrid(from);
    var (tx, ty) = _worldToGrid(to);

    if (!isCellWalkable(sx, sy)) {
      final alt = _findNearestWalkable(sx, sy);
      if (alt == null) return <Vector2>[];
      (sx, sy) = alt;
    }

    if (!isCellWalkable(tx, ty)) {
      final alt = _findNearestWalkable(tx, ty);
      if (alt == null) return <Vector2>[];
      (tx, ty) = alt;
    }

    final start = sy * _gridWidth + sx;
    final goal = ty * _gridWidth + tx;

    final open = <int>[start];
    final cameFrom = List<int>.filled(_gridWidth * _gridHeight, -1);
    final gScore = List<double>.filled(_gridWidth * _gridHeight, double.infinity);
    final fScore = List<double>.filled(_gridWidth * _gridHeight, double.infinity);
    gScore[start] = 0;
    fScore[start] = _heuristic(sx, sy, tx, ty);

    const neighbors = <(int, int, double)>[
      (1, 0, 1.0),
      (-1, 0, 1.0),
      (0, 1, 1.0),
      (0, -1, 1.0),
      (1, 1, 1.4),
      (1, -1, 1.4),
      (-1, 1, 1.4),
      (-1, -1, 1.4),
    ];

    while (open.isNotEmpty) {
      var bestIdx = 0;
      var bestScore = fScore[open[0]];
      for (var i = 1; i < open.length; i++) {
        final s = fScore[open[i]];
        if (s < bestScore) {
          bestScore = s;
          bestIdx = i;
        }
      }
      final current = open.removeAt(bestIdx);
      if (current == goal) {
        return _reconstructPath(cameFrom, current);
      }

      final cx = current % _gridWidth;
      final cy = current ~/ _gridWidth;

      for (final (dx, dy, cost) in neighbors) {
        final nx = cx + dx;
        final ny = cy + dy;
        if (!isCellWalkable(nx, ny)) continue;

        // Не даём резать углы по диагонали.
        if (dx != 0 && dy != 0) {
          if (!isCellWalkable(cx + dx, cy) || !isCellWalkable(cx, cy + dy)) {
            continue;
          }
        }

        final ni = ny * _gridWidth + nx;
        final tentative = gScore[current] + cost;
        if (tentative < gScore[ni]) {
          cameFrom[ni] = current;
          gScore[ni] = tentative;
          fScore[ni] = tentative + _heuristic(nx, ny, tx, ty);
          if (!open.contains(ni)) open.add(ni);
        }
      }
    }

    return <Vector2>[];
  }

  double _heuristic(int x, int y, int tx, int ty) {
    final dx = (tx - x).abs();
    final dy = (ty - y).abs();
    return (dx + dy).toDouble();
  }

  (int, int)? _findNearestWalkable(int sx, int sy) {
    const maxRadius = 6;
    for (var r = 1; r <= maxRadius; r++) {
      for (var y = -r; y <= r; y++) {
        for (var x = -r; x <= r; x++) {
          final gx = sx + x;
          final gy = sy + y;
          if (isCellWalkable(gx, gy)) return (gx, gy);
        }
      }
    }
    return null;
  }

  List<Vector2> _reconstructPath(List<int> cameFrom, int current) {
    final path = <Vector2>[];
    var cur = current;
    while (cur != -1) {
      final gx = cur % _gridWidth;
      final gy = cur ~/ _gridWidth;
      path.add(gridToWorldCenter(gx, gy));
      cur = cameFrom[cur];
    }
    return path.reversed.toList();
  }

  bool hasLineOfSight(Vector2 from, Vector2 to) {
    if (_collisionRects.isEmpty) return true;
    for (final r in _collisionRects) {
      if (_segmentRectHitT(from, to, r) != null) return false;
    }
    return true;
  }

  double? _segmentRectHitT(Vector2 a, Vector2 b, Rect r) {
    final ax = a.x;
    final ay = a.y;
    final bx = b.x;
    final by = b.y;
    final dx = bx - ax;
    final dy = by - ay;

    double t0 = 0.0;
    double t1 = 1.0;

    bool clip(double p, double q) {
      if (p == 0) return q >= 0;
      final t = q / p;
      if (p < 0) {
        if (t > t1) return false;
        if (t > t0) t0 = t;
      } else {
        if (t < t0) return false;
        if (t < t1) t1 = t;
      }
      return true;
    }

    if (!clip(-dx, ax - r.left)) return null;
    if (!clip(dx, r.right - ax)) return null;
    if (!clip(-dy, ay - r.top)) return null;
    if (!clip(dy, r.bottom - ay)) return null;

    return t0;
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

class _TiledCollisionBlock extends PositionComponent with CollisionCallbacks, SolidObstacle {
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
  Rect get collisionRect => Rect.fromLTWH(position.x, position.y, size.x, size.y);

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

class _TiledHoleBlock extends PositionComponent
    with CollisionCallbacks, SolidObstacle, ProjectilePassThrough {
  _TiledHoleBlock({
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
  Rect get collisionRect => Rect.fromLTWH(position.x, position.y, size.x, size.y);

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
      ..color = const Color(0x6681C784)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (isEllipse && size.x == size.y) {
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
      return;
    }

    canvas.drawRect(size.toRect(), paint);
  }
}
