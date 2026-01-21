/// Константы игры.
/// Здесь держим числа, чтобы не раскидывать магию по коду.
abstract class GameConstants {
  // Размер фиксированной камеры (горизонтальный формат).
  static const double cameraWidth = 800;
  static const double cameraHeight = 450;

  // Длительность биома в секундах (0.1).
  static const double biomeDurationSeconds = 250; // 7 минут
  static const double bossSpawnTimeLeftSeconds = 240; // 4 минуты до конца биома
  static const double bossWarningLeadSeconds = 5; // предупреждение за N секунд до босса
  static const double baseEliteChance = 0.04; // базовый шанс элитных без предметов

  // Размер карты мира (позже будет тайлсет/генерация).
  static const double mapWidth = 4000;
  static const double mapHeight = 2500;

  // Как далеко от игрока спавним мобов.
  static const double enemySpawnMinDist = 520;
  static const double enemySpawnMaxDist = 780;
  static const double eliteBaseXpMultiplier = 2.0;

  // Период появления карты угрозы.
  static const double threatCardPeriodSeconds = 14;

  // Минимальные дистанции для интерактивов.
  static const double interactableMinDistFromPlayer = 220;
  static const double interactableMinDistBetween = 140;
  static const int interactableSpawnAttempts = 60;
}
