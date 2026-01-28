import 'package:pixel_clash/game/config/game_constants.dart';

/// Модификаторы текущего рана (только локально для игрока).
///
/// Важно для будущего мультиплеера:
/// - Эти значения НЕ должны менять карту (интерактивы, ключи и т.п.)
/// - Эти значения могут менять только "темп" и "сложность" рана игрока:
///   например частоту спавна мобов.
///
/// Сейчас используем только множитель частоты спавна врагов (без элиток).
class RunModifiers {
  /// Суммарная прибавка к частоте спавна.
  /// Пример: 0.25 => +25% к спавну.
  double enemySpawnRateAdd = 0.0;

  /// Удача: влияет на шансы редкости наград.
  double luckBonusLevelUpAdd = 0.0;
  double luckBonusAltarAdd = 0.0;

  /// Множитель получаемого XP.
  double xpGainAdd = 0.0;

  /// Шанс появления элитных врагов.
  double eliteChanceAdd = 0.0;

  double eliteHpMultiplier = 1.0;
  double eliteDmgMultiplier = 1.0;
  double eliteScoreMultiplier = 1.0;
  double eliteXpMultiplier = 1.0;

  /// Множитель урона по боссам (игроком).
  double bossDamageMultiplier = 1.0;

  /// Итоговый множитель частоты спавна врагов.
  /// Всегда минимум 1.0.
  double get enemySpawnRateMultiplier => (1.0 + enemySpawnRateAdd).clamp(1.0, 10.0);

  double get luckBonusLevelUp => luckBonusLevelUpAdd.clamp(0.0, 1.0);
  double get luckBonusAltar => luckBonusAltarAdd.clamp(0.0, 1.0);

  double get xpGainMultiplier => (1.0 + xpGainAdd).clamp(0.1, 5.0);

  double get eliteChance =>
      (GameConstants.baseEliteChance + eliteChanceAdd).clamp(0.0, 0.8);

  /// Сброс модификаторов при старте нового рана.
  void reset() {
    enemySpawnRateAdd = 0.0;
    luckBonusLevelUpAdd = 0.0;
    luckBonusAltarAdd = 0.0;
    xpGainAdd = 0.0;
    eliteChanceAdd = 0.0;
    eliteHpMultiplier = 1.0;
    eliteDmgMultiplier = 1.0;
    eliteScoreMultiplier = 1.0;
    eliteXpMultiplier = 1.0;
    bossDamageMultiplier = 1.0;
  }
}
