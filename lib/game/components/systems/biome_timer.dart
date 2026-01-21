import 'dart:async';

import 'package:flame/components.dart' hide Timer;
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
  DateTime? _startTime;
  Timer? _ticker;

  void resetAndStart() {
    _timeLeft = durationSeconds;
    _isRunning = true;
    _isOver = false;
    _startTime = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    onTimeChanged(_timeLeft);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Логика таймера обновляется реальным временем через Timer.
  }

  void _tick() {
    if (!_isRunning || _isOver) return;

    final start = _startTime;
    if (start == null) return;

    final elapsed = DateTime.now().difference(start).inMilliseconds / 1000.0;
    _timeLeft = (durationSeconds - elapsed).clamp(0.0, durationSeconds);

    if (_timeLeft <= 0) {
      _timeLeft = 0;
      _isOver = true;
      _isRunning = false;
      _ticker?.cancel();
      onTimeChanged(_timeLeft);
      onTimeIsOver();
      return;
    }

    onTimeChanged(_timeLeft);
  }

  @override
  void onRemove() {
    _ticker?.cancel();
    super.onRemove();
  }
}
