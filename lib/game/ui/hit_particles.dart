import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Пиксельные частицы при попадании (простые "искры").
/// Добавляем ParticleSystemComponent в parent (обычно worldMap).
void spawnHitParticles({
  required Component parent,
  required Vector2 position,
  required Color color,
  int count = 10,
}) {
  final rng = Random();

  parent.add(
    ParticleSystemComponent(
      position: position.clone(),
      anchor: Anchor.center,
      particle: Particle.generate(
        count: count,
        lifespan: 0.22,
        generator: (i) {
          // Случайная скорость (разлёт).
          final vx = (rng.nextDouble() * 2 - 1) * 220; // -220..220
          final vy = (rng.nextDouble() * 2 - 1) * 220;

          // Небольшая "гравитация", чтобы частицы падали.
          const gravity = 380.0;

          // Размер "пикселя"
          const px = 3.0;

          return AcceleratedParticle(
            speed: Vector2(vx, vy),
            acceleration: Vector2(0, gravity),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                // Плавное затухание
                final t = (1 - particle.progress).clamp(0.0, 1.0);
                final paint = Paint()..color = color.withValues(alpha: t);

                // Рисуем маленький квадратик
                canvas.drawRect(
                  const Rect.fromLTWH(-px / 2, -px / 2, px, px),
                  paint,
                );
              },
            ),
          );
        },
      ),
    ),
  );
}
