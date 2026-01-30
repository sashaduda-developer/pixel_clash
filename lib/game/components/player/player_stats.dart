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
