import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('RewardDbRow')
class RewardDefinitions extends Table {
  /// PK: "${source}_${id}_${rarity}"
  TextColumn get key => text()();

  /// base id: "stat_hp", "buff_vampirism" ...
  TextColumn get id => text()();

  /// "levelUp" | "chest" | "altar" | "vendor"
  TextColumn get source => text()();

  /// "buff" | "ability" | "item" | "stat"
  TextColumn get kind => text()();

  /// "common" | "rare" | "epic" | "legendary"
  TextColumn get rarity => text()();

  RealColumn get weight => real().withDefault(const Constant(1.0))();

  TextColumn get titleKey => text()();
  TextColumn get descKey => text()();

  TextColumn get iconKey => text().withDefault(const Constant('stat'))();
  TextColumn get paramsJson => text().withDefault(const Constant('{}'))();

  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [RewardDefinitions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  /// Так как проект ранний — делаем простую миграцию:
  /// при переходе на v2 пересоздаём таблицу reward_definitions.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.deleteTable('reward_definitions');
            await m.createAll();
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'pixel_clash.sqlite',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationDocumentsDirectory,
      ),
    );
  }
}
