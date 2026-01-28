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
    required this.maxMana,
    required this.mana,
    this.manaRegen = 2.0,
    this.hpRegen = 0.0,
    this.evasionChance = 0.0,
    this.critChance = 0.15,
    this.critMultiplier = 1.8,
    this.healMultiplier = 1.0,
  });

  int maxHp;
  int hp;

  double _hpRegenCarry = 0.0;

  int armor;
  int damage;

  /// Атак в секунду.
  double attackSpeed;

  /// Скорость перемещения (пикс/сек).
  double moveSpeed;

  double maxMana;
  double mana;
  double manaRegen;
  double hpRegen;
  double evasionChance;

  /// Шанс критического удара (0..1).
  double critChance;

  /// Множитель критического удара (например 1.8 = +80% урона).
  double critMultiplier;

  /// Множитель получаемого лечения.
  double healMultiplier;

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
          maxMana: 100,
          mana: 100,
          manaRegen: 2.2,
          hpRegen: 0.0,
          evasionChance: 0.0,
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
          maxMana: 90,
          mana: 90,
          manaRegen: 2.5,
          hpRegen: 0.0,
          evasionChance: 0.0,
          critChance: 0.15,
          critMultiplier: 1.8,
        );
      case HeroType.mage:
        return PlayerStats(
          maxHp: 60,
          hp: 60,
          armor: 0,
          damage: 12,
          attackSpeed: 0.75,
          moveSpeed: 175,
          maxMana: 140,
          mana: 140,
          manaRegen: 2.0,
          hpRegen: 0.0,
          evasionChance: 0.0,
          critChance: 0.12,
          critMultiplier: 1.7,
        );
      case HeroType.ninja:
        return PlayerStats(
          maxHp: 65,
          hp: 65,
          armor: 0,
          damage: 9,
          attackSpeed: 1.45,
          moveSpeed: 215,
          maxMana: 80,
          mana: 80,
          manaRegen: 2.4,
          hpRegen: 0.0,
          evasionChance: 0.10,
          critChance: 0.18,
          critMultiplier: 1.7,
        );
    }
  }

  /// Лечение (не выше maxHp).
  void heal(int value) {
    if (value <= 0) return;
    final mult = healMultiplier.clamp(0.0, 10.0);
    final effective = (value * mult).round();
    if (effective <= 0) return;
    hp = (hp + effective).clamp(0, maxHp);
  }


  bool regenHp(double dt) {
    if (hpRegen <= 0) return false;
    if (hp <= 0) return false;
    if (hp >= maxHp) return false;

    final gain = hpRegen * dt * healMultiplier;
    _hpRegenCarry += gain;
    final add = _hpRegenCarry.floor();
    if (add <= 0) return false;

    _hpRegenCarry -= add;
    hp = (hp + add).clamp(0, maxHp);
    return true;
  }
  bool regenMana(double dt) {
    if (manaRegen <= 0 || maxMana <= 0) return false;
    if (mana >= maxMana) return false;

    final next = (mana + manaRegen * dt).clamp(0, maxMana).toDouble();
    if (next == mana) return false;
    mana = next;
    return true;
  }

  bool spendMana(double amount) {
    if (amount <= 0) return true;
    if (mana < amount) return false;
    mana -= amount;
    return true;
  }
}
