/// Редкость награды/перка/способности.
///
/// Важно:
/// - Редкость нужна не только для UI (цвет), но и для баланса:
///   веса выпадения, сила эффекта, цена у торговца и т.д.
enum Rarity {
  common,
  rare,
  epic,
  legendary,
}

extension RarityX on Rarity {
  String get id => switch (this) {
        Rarity.common => 'common',
        Rarity.rare => 'rare',
        Rarity.epic => 'epic',
        Rarity.legendary => 'legendary',
      };

  /// Базовые веса для выпадения (можно менять по источнику: level-up / altar / chest / vendor).
  double get baseWeight => switch (this) {
        Rarity.common => 70,
        Rarity.rare => 22,
        Rarity.epic => 7,
        Rarity.legendary => 1,
      };
}
