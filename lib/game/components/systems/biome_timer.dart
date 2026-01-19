import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Таймер биома.
/// По правилам: если таймер дошёл до нуля и игрок не в портале — проигрыш.
/// В 0.1 портала ещё нет, поэтому это просто конец раунда.
class BiomeTimer extends Component {
  BiomeTimer({
    required this.durationSeconds,
    required this.onTimeChanged,
    required this.onTimeIsOver,
  });

  final double durationSeconds;
  final void Function(double timeLeft) onTimeChanged;
  final VoidCallback onTimeIsOver;

  double _timeLeft = 0;
  bool _isRunning = false;
  bool _isOver = false;

  void resetAndStart() {
    _timeLeft = durationSeconds;
    _isRunning = true;
    _isOver = false;
    onTimeChanged(_timeLeft);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isRunning || _isOver) return;

    _timeLeft -= dt;

    if (_timeLeft <= 0) {
      _timeLeft = 0;
      _isOver = true;
      onTimeChanged(_timeLeft);
      onTimeIsOver();
      return;
    }

    onTimeChanged(_timeLeft);
  }
}
