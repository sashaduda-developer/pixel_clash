import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

/// Конвертация "логических" радиусов (из сидера) в игровые пиксели.
double altarRadius(double raw) => raw * 100.0;

double altarNum(Map<String, Object?> values, String key, double fallback) {
  final v = values[key];
  if (v is num) return v.toDouble();
  return fallback;
}

int altarInt(Map<String, Object?> values, String key, int fallback) {
  final v = values[key];
  if (v is num) return v.toInt();
  return fallback;
}

Iterable<EnemyComponent> enemiesInRadius(
  PixelClashGame game,
  Vector2 center,
  double radius,
) sync* {
  final r2 = radius * radius;
  for (final c in game.worldMap.children) {
    if (c is! EnemyComponent) continue;
    if (c.isDead || c.isRemoving) continue;
    if (c.position.distanceToSquared(center) > r2) continue;
    yield c;
  }
}

List<EnemyComponent> nearestEnemies(
  PixelClashGame game,
  Vector2 center,
  double radius,
  int count,
) {
  final list = <EnemyComponent>[];
  final r2 = radius * radius;

  for (final c in game.worldMap.children) {
    if (c is! EnemyComponent) continue;
    if (c.isDead || c.isRemoving) continue;
    if (c.position.distanceToSquared(center) > r2) continue;
    list.add(c);
  }

  list.sort((a, b) {
    final da = a.position.distanceToSquared(center);
    final db = b.position.distanceToSquared(center);
    return da.compareTo(db);
  });

  if (list.length <= count) return list;
  return list.sublist(0, count);
}
