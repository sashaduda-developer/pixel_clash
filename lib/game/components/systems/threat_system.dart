import 'package:flame/components.dart';

/// Система угрозы (Threat).
/// Уровень угрозы влияет на:
/// - частоту/силу спавна
/// - множитель награды (score)
class ThreatSystem extends Component {
  ThreatSystem({required this.onThreatChanged});

  final void Function(int value) onThreatChanged;

  int _level = 0;

  int get level => _level;

  /// Множитель score (простая формула для 0.1).
  double get scoreMultiplier => 1.0 + _level * 0.25;

  void reset() {
    _level = 0;
    onThreatChanged(_level);
  }

  void increaseThreat() {
    _level += 1;
    onThreatChanged(_level);
  }
}
