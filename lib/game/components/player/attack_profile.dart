import 'package:flutter/material.dart';

class AttackProfile {
  const AttackProfile({
    required this.range,
    required this.meleeRadius,
    required this.projectileSpeed,
    required this.projectileColor,
    required this.projectileSize,
    required this.samuraiHits,
    required this.samuraiHitDelaySec,
  });

  final double range;
  final double meleeRadius;
  final double projectileSpeed;
  final Color projectileColor;
  final Size projectileSize;
  final int samuraiHits;
  final double samuraiHitDelaySec;
}
