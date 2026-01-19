/// Константы игры.
/// Здесь держим числа, чтобы не раскидывать магию по коду.
abstract class GameConstants {
  // Размер фиксированной камеры (горизонтальный формат).
  static const double cameraWidth = 800;
  static const double cameraHeight = 450;

  // Длительность биома в секундах (0.1).
  static const double biomeDurationSeconds = 240; // 4 минуты

  // Размер карты мира (позже будет тайлсет/генерация).
  static const double mapWidth = 4000;
  static const double mapHeight = 2500;

  // Как далеко от игрока спавним мобов.
  static const double enemySpawnMinDist = 520;
  static const double enemySpawnMaxDist = 780;

  // Период появления карты угрозы.
  static const double threatCardPeriodSeconds = 14;
}
