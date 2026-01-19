import 'package:flame/components.dart';

/// Система очков (Score).
/// Важно: НЕЛЬЗЯ называть метод `add`, потому что у Component уже есть `add(Component)`.
/// Поэтому используем `addScore`.
class ScoreSystem extends Component {
  ScoreSystem({required this.onScoreChanged});

  final void Function(int value) onScoreChanged;

  int _score = 0;

  int get value => _score;

  void reset() {
    _score = 0;
    onScoreChanged(_score);
  }

  /// Добавить очки.
  void addScore(int delta) {
    _score += delta;
    onScoreChanged(_score);
  }
}
