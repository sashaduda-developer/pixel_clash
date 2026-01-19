import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pixel_clash/game/data/app_database.dart';

class RewardSeeder {
  /// ВАЖНО:
  /// Поднимаем версию сида, чтобы новые данные реально начали использоваться.
  /// Старые записи в БД остаются, но репозиторий будет брать только текущую version.
  static const int currentVersion = 3;

  static Future<void> ensureSeeded(AppDatabase db) async {
    // ===== Само-ремонт данных =====
    // levelUp = только статы, поэтому любые бафы оттуда вычищаем.
    await (db.delete(db.rewardDefinitions)
          ..where((t) => t.source.equals('levelUp'))
          ..where((t) => t.kind.equals('buff')))
        .go();

    // Если уже есть строки текущей версии — ничего не делаем.
    // НО: у тебя сейчас версия "битая" (вставилось не всё),
    // поэтому мы принудительно пересидим текущую версию целиком.
    //
    // Чтобы не ловить странные конфликтные состояния, проще удалить текущую версию и вставить заново.
    await (db.delete(db.rewardDefinitions)..where((t) => t.version.equals(currentVersion))).go();

    final rows = <RewardDefinitionsCompanion>[
      // ===========================
      // LEVEL UP — только СТАТЫ
      // ===========================
      ..._statVariants(
        source: 'levelUp',
        id: 'stat_hp',
        titleKey: 'upg_hp_title',
        descKey: 'upg_hp_desc',
        stat: 'hp',
        iconKey: 'stat',
        common: 10,
        rare: 20,
        epic: 35,
        legendary: 50,
      ),
      ..._statVariants(
        source: 'levelUp',
        id: 'stat_damage',
        titleKey: 'upg_damage_title',
        descKey: 'upg_damage_desc',
        stat: 'damage',
        iconKey: 'stat',
        common: 2,
        rare: 4,
        epic: 6,
        legendary: 8,
      ),
      ..._statVariants(
        source: 'levelUp',
        id: 'stat_attackSpeed',
        titleKey: 'upg_as_title',
        descKey: 'upg_as_desc',
        stat: 'attackSpeed',
        iconKey: 'stat',
        common: 0.10,
        rare: 0.15,
        epic: 0.20,
        legendary: 0.25,
      ),
      ..._statVariants(
        source: 'levelUp',
        id: 'stat_armor',
        titleKey: 'upg_armor_title',
        descKey: 'upg_armor_desc',
        stat: 'armor',
        iconKey: 'shield',
        common: 1,
        rare: 2,
        epic: 3,
        legendary: 4,
      ),
      ..._statVariants(
        source: 'levelUp',
        id: 'stat_critChance',
        titleKey: 'upg_crit_title',
        descKey: 'upg_crit_desc',
        stat: 'critChance',
        iconKey: 'bolt',
        common: 0.03,
        rare: 0.05,
        epic: 0.07,
        legendary: 0.10,
      ),
      ..._statVariants(
        source: 'levelUp',
        id: 'stat_moveSpeed',
        titleKey: 'upg_ms_title',
        descKey: 'upg_ms_desc',
        stat: 'moveSpeed',
        iconKey: 'stat',
        common: 12,
        rare: 20,
        epic: 30,
        legendary: 45,
      ),

      // ===========================
      // CHEST — предметы
      // ===========================
      _row(
        source: 'chest',
        id: 'item_book_hardship',
        kind: 'item',
        rarity: 'common',
        weight: 1,
        titleKey: 'chest_book_hardship_title',
        descKey: 'chest_book_hardship_desc',
        iconKey: 'book',
        params: {'spawnRateAdd': 0.25},
      ),
      _row(
        source: 'chest',
        id: 'item_book_hardship',
        kind: 'item',
        rarity: 'rare',
        weight: 1,
        titleKey: 'chest_book_hardship_title',
        descKey: 'chest_book_hardship_desc',
        iconKey: 'book',
        params: {'spawnRateAdd': 0.40},
      ),
      _row(
        source: 'chest',
        id: 'item_book_hardship',
        kind: 'item',
        rarity: 'epic',
        weight: 1,
        titleKey: 'chest_book_hardship_title',
        descKey: 'chest_book_hardship_desc',
        iconKey: 'book',
        params: {'spawnRateAdd': 0.60},
      ),
      _row(
        source: 'chest',
        id: 'item_book_hardship',
        kind: 'item',
        rarity: 'legendary',
        weight: 1,
        titleKey: 'chest_book_hardship_title',
        descKey: 'chest_book_hardship_desc',
        iconKey: 'book',
        params: {'spawnRateAdd': 0.85},
      ),

      // ===========================
      // ALTAR — магия (buffs)
      // ===========================
      ..._buffVariants(
        source: 'altar',
        id: 'buff_chain_lightning',
        titleKey: 'altar_chain_lightning_title',
        descKey: 'altar_chain_lightning_desc',
        iconKey: 'bolt',
        common: {'procChance': 0.08},
        rare: {'procChance': 0.12},
        epic: {'procChance': 0.18},
        legendary: {'procChance': 0.25},
      ),
      ..._buffVariants(
        source: 'altar',
        id: 'buff_vampirism',
        titleKey: 'altar_vamp_title',
        descKey: 'altar_vamp_desc',
        iconKey: 'bolt',
        common: {'lifesteal': 0.03},
        rare: {'lifesteal': 0.05},
        epic: {'lifesteal': 0.07},
        legendary: {'lifesteal': 0.10},
      ),
      _row(
        source: 'altar',
        id: 'buff_freeze_stub',
        kind: 'buff',
        rarity: 'common',
        weight: 1,
        titleKey: 'altar_freeze_title',
        descKey: 'altar_freeze_desc',
        iconKey: 'snow',
        params: {},
      ),
      _row(
        source: 'altar',
        id: 'buff_thorns_stub',
        kind: 'buff',
        rarity: 'common',
        weight: 1,
        titleKey: 'altar_thorns_title',
        descKey: 'altar_thorns_desc',
        iconKey: 'shield',
        params: {},
      ),
    ];

    await db.batch((b) {
      // ВАЖНО: теперь не "insertOrIgnore", а обычный insert.
      // Мы перед этим удалили текущую версию, поэтому конфликтов не будет.
      b.insertAll(db.rewardDefinitions, rows);
    });
  }

  // ---------- helpers ----------

  static List<RewardDefinitionsCompanion> _statVariants({
    required String source,
    required String id,
    required String titleKey,
    required String descKey,
    required String stat,
    required String iconKey,
    required Object common,
    required Object rare,
    required Object epic,
    required Object legendary,
  }) {
    return [
      _statRow(
        source: source,
        id: id,
        rarity: 'common',
        weight: 1,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: {'stat': stat, 'delta': common},
      ),
      _statRow(
        source: source,
        id: id,
        rarity: 'rare',
        weight: 1,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: {'stat': stat, 'delta': rare},
      ),
      _statRow(
        source: source,
        id: id,
        rarity: 'epic',
        weight: 1,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: {'stat': stat, 'delta': epic},
      ),
      _statRow(
        source: source,
        id: id,
        rarity: 'legendary',
        weight: 1,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: {'stat': stat, 'delta': legendary},
      ),
    ];
  }

  static List<RewardDefinitionsCompanion> _buffVariants({
    required String source,
    required String id,
    required String titleKey,
    required String descKey,
    required String iconKey,
    required Map<String, Object?> common,
    required Map<String, Object?> rare,
    required Map<String, Object?> epic,
    required Map<String, Object?> legendary,
  }) {
    return [
      _row(
        source: source,
        id: id,
        kind: 'buff',
        rarity: 'common',
        weight: 1,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: common,
      ),
      _row(
        source: source,
        id: id,
        kind: 'buff',
        rarity: 'rare',
        weight: 1,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: rare,
      ),
      _row(
        source: source,
        id: id,
        kind: 'buff',
        rarity: 'epic',
        weight: 1,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: epic,
      ),
      _row(
        source: source,
        id: id,
        kind: 'buff',
        rarity: 'legendary',
        weight: 1,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: legendary,
      ),
    ];
  }

  static RewardDefinitionsCompanion _statRow({
    required String source,
    required String id,
    required String rarity,
    required double weight,
    required String titleKey,
    required String descKey,
    required String iconKey,
    required Map<String, Object?> params,
  }) {
    return _row(
      source: source,
      id: id,
      kind: 'stat',
      rarity: rarity,
      weight: weight,
      titleKey: titleKey,
      descKey: descKey,
      iconKey: iconKey,
      params: params,
    );
  }

  static RewardDefinitionsCompanion _row({
    required String source,
    required String id,
    required String kind,
    required String rarity,
    required double weight,
    required String titleKey,
    required String descKey,
    required String iconKey,
    required Map<String, Object?> params,
  }) {
    // ВАЖНО:
    // PK = key, поэтому key должен быть уникальным во всей таблице.
    // Так как мы храним несколько версий, добавляем version в key.
    final k = 'v${currentVersion}_${source}_${id}_$rarity';

    return RewardDefinitionsCompanion(
      key: Value(k),
      id: Value(id),
      source: Value(source),
      kind: Value(kind),
      rarity: Value(rarity),
      weight: Value(weight),
      titleKey: Value(titleKey),
      descKey: Value(descKey),
      iconKey: Value(iconKey),
      paramsJson: Value(jsonEncode(params)),
      version: const Value(currentVersion),
    );
  }
}
