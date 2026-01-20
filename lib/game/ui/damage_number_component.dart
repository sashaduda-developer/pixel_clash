import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Плавающая цифра урона.
/// - появляется в точке
/// - летит вверх
/// - слегка "шатается" по X
/// - затухает и удаляется
class DamageNumberComponent extends PositionComponent {
  DamageNumberComponent({
    required super.position,
    required this.value,
    required this.color,
    this.label,
    this.lifeSeconds = 0.7,
    this.riseSpeed = 32,
    this.scaleFactor = 1.0,
  });

  /// Значение урона.
  final int value;

  /// Цвет текста.
  final Color color;

  /// Текст вместо числа (например, "MISS").
  final String? label;

  /// Сколько живёт (сек).
  final double lifeSeconds;

  /// Скорость подъёма (пикс/сек).
  final double riseSpeed;

  final double scaleFactor;

  late final TextComponent _text;
  late final String _displayText;

  double _life = 0;

  // Маленький случайный "шаг" по X, чтобы цифры выглядели живее.
  late final double _xJitter = (Random().nextDouble() * 2 - 1) * 10; // -10..10

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    anchor = Anchor.center;
    _displayText = label ?? value.toString();

    _text = TextComponent(
      text: _displayText,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          shadows: const [
            Shadow(
              blurRadius: 2,
              offset: Offset(1, 1),
              color: Colors.black,
            ),
          ],
        ),
      ),
    );

    _text.scale = Vector2.all(scaleFactor);

    add(_text);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _life += dt;

    // Двигаемся вверх + лёгкая "болтанка" по X
    position.y -= riseSpeed * dt;
    position.x += _xJitter * dt * 0.12;

    // Фейд-аут
    final t = (_life / lifeSeconds).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);

    // В Flame проще всего менять цвет рендера через TextPaint.
    // Поэтому переустанавливаем стиль (это нормально для прототипа).
    _text.textRenderer = TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: 14,
        fontWeight: FontWeight.w700,
        shadows: const [
          Shadow(
            blurRadius: 2,
            offset: Offset(1, 1),
            color: Colors.black,
          ),
        ],
      ),
    );

    if (_life >= lifeSeconds) {
      removeFromParent();
    }
  }
}
