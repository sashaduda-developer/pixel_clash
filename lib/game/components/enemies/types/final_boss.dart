import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';

class FinalBossComponent extends EnemyComponent {
  FinalBossComponent({
    required super.position,
    super.speed = 85,
    super.hp = 360,
    super.damage = 18,
    super.scoreReward = 90,
    super.xpReward = 65,
  });

  @override
  bool get isBoss => true;

  @override
  String get bossName => 'Portal Overlord';

  @override
  Color get baseColor => const Color(0xFFD32F2F);

  @override
  Color get flashColor => const Color(0xFFFFCDD2);

  @override
  Color get hpFillColor => const Color(0xFFE53935);

  @override
  double get bodySize => 78;

  @override
  double get hitboxRadius => 36;

  @override
  double get hpBarHeight => 8.0;

  @override
  bool get drawEliteBorder => true;

  @override
  Color get eliteBorderColor => const Color(0x99FFFFFF);
}
