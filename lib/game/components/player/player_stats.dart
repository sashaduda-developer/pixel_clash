import 'package:pixel_clash/game/components/player/hero_type.dart';

/// Статы игрока.
/// Важно: это "живые" данные, апгрейды меняют их прямо во время забега.
class PlayerStats {
  PlayerStats({
    required this.maxHp,
    required this.hp,
    required this.armor,
    required this.damage,
    required this.attackSpeed,
    required this.moveSpeed,
    this.critChance = 0.15,
    this.critMultiplier = 1.8,
  });

  int maxHp;
  int hp;

  int armor;
  int damage;

  /// Атак в секунду.
  double attackSpeed;

  /// Скорость перемещения (пикс/сек).
  double moveSpeed;

  /// Шанс критического удара (0..1).
  double critChance;

  /// Множитель критического удара (например 1.8 = +80% урона).
  double critMultiplier;

  factory PlayerStats.forHero(HeroType type) {
    switch (type) {
      case HeroType.ranger:
        return PlayerStats(
          maxHp: 70,
          hp: 70,
          armor: 0,
          damage: 10,
          attackSpeed: 1.2,
          moveSpeed: 190,
          critChance: 0.15,
          critMultiplier: 1.8,
        );
      case HeroType.knight:
        return PlayerStats(
          maxHp: 110,
          hp: 110,
          armor: 2,
          damage: 14,
          attackSpeed: 0.9,
          moveSpeed: 165,
          critChance: 0.15,
          critMultiplier: 1.8,
        );
    }
  }

  /// Лечение (не выше maxHp).
  void heal(int value) {
    if (value <= 0) return;
    hp = (hp + value).clamp(0, maxHp);
  }
}
