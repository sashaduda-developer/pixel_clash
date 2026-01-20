import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/player/hero_type.dart';

enum AttackStyle {
  ranger,
  knight,
  mage,
  ninja,
}

class AttackProfile {
  const AttackProfile({
    required this.style,
    required this.range,
    required this.meleeRadius,
    required this.projectileSpeed,
    required this.projectileColor,
    required this.projectileSize,
    required this.waveDamageMultiplier,
    required this.ninjaHits,
    required this.ninjaHitDelaySec,
  });

  final AttackStyle style;
  final double range;
  final double meleeRadius;
  final double projectileSpeed;
  final Color projectileColor;
  final Size projectileSize;
  final double waveDamageMultiplier;
  final int ninjaHits;
  final double ninjaHitDelaySec;

  factory AttackProfile.forHero(HeroType type) {
    switch (type) {
      case HeroType.ranger:
        return const AttackProfile(
          style: AttackStyle.ranger,
          range: 420,
          meleeRadius: 0,
          projectileSpeed: 520,
          projectileColor: Color(0xFFFFD54F),
          projectileSize: Size(18, 4),
          waveDamageMultiplier: 0.0,
          ninjaHits: 0,
          ninjaHitDelaySec: 0,
        );
      case HeroType.knight:
        return const AttackProfile(
          style: AttackStyle.knight,
          range: 260,
          meleeRadius: 52,
          projectileSpeed: 420,
          projectileColor: Color(0xFFFFB74D),
          projectileSize: Size(26, 6),
          waveDamageMultiplier: 0.60,
          ninjaHits: 0,
          ninjaHitDelaySec: 0,
        );
      case HeroType.mage:
        return const AttackProfile(
          style: AttackStyle.mage,
          range: 480,
          meleeRadius: 0,
          projectileSpeed: 360,
          projectileColor: Color(0xFFFF8A65),
          projectileSize: Size(22, 22),
          waveDamageMultiplier: 0.0,
          ninjaHits: 0,
          ninjaHitDelaySec: 0,
        );
      case HeroType.ninja:
        return const AttackProfile(
          style: AttackStyle.ninja,
          range: 220,
          meleeRadius: 38,
          projectileSpeed: 0,
          projectileColor: Color(0xFFFFFFFF),
          projectileSize: Size(0, 0),
          waveDamageMultiplier: 0.0,
          ninjaHits: 2,
          ninjaHitDelaySec: 0.08,
        );
    }
  }
}
