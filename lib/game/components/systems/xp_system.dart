import 'package:flame/components.dart';

/// Система опыта/уровня.
///
/// Логика:
/// - addXp() вызывается при убийстве мобов
/// - если набрал порог -> уровень++
/// - дальше сообщает наружу через onLevelUp (игра ставит паузу и показывает overlay)
class XpSystem extends Component {
  XpSystem({
    required this.onXpChanged,
    required this.onLevelChanged,
    required this.onLevelUp,
  });

  final void Function(double currentXp, int xpToNext) onXpChanged;
  final void Function(int level) onLevelChanged;

  /// Вызывается, когда произошёл level up.
  final void Function(int newLevel) onLevelUp;

  int _level = 1;
  double _xp = 0;
  int _xpToNext = 12;

  int get level => _level;
  double get xp => _xp;
  int get xpToNext => _xpToNext;

  void reset() {
    _level = 1;
    _xp = 0;
    _xpToNext = 12;
    onLevelChanged(_level);
    onXpChanged(_xp, _xpToNext);
  }

  void addXp(num value) {
    if (value <= 0) return;

    _xp += value.toDouble();

    // Может быть несколько уровней за раз, поэтому while.
    while (_xp >= _xpToNext) {
      _xp -= _xpToNext;
      _level++;

      // Рост порога — мягкая прогрессия для прототипа.
      _xpToNext = _calcNextXp(_level);

      onLevelChanged(_level);
      onLevelUp(_level);
    }

    onXpChanged(_xp, _xpToNext);
  }

  int _calcNextXp(int level) {
    // Slightly super-linear curve to slow late-game leveling.
    final l = level > 1 ? level - 1 : 0;
    final quad = (l * l * 0.6).round();
    return 12 + l * 5 + quad;
  }
}
