import 'package:pixel_clash/game/components/combat/buff.dart';

/// Базовый бафф с таблицей значений по уровням.
abstract class LevelBasedBuff extends Buff {
  LevelBasedBuff({
    required super.id,
    required super.rarity,
    required this.maxLevel,
    required Map<int, Map<String, Object?>> levels,
  }) : _levels = levels;

  /// Максимальный уровень баффа.
  final int maxLevel;

  final Map<int, Map<String, Object?>> _levels;

  /// Значения для текущего уровня (с ограничением maxLevel).
  Map<String, Object?> levelValues() {
    var lvl = level;
    if (lvl < 1) lvl = 1;
    if (lvl > maxLevel) lvl = maxLevel;
    return _levels[lvl] ?? const <String, Object?>{};
  }
}
