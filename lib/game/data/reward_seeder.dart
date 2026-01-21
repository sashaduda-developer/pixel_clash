import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pixel_clash/game/data/app_database.dart';

class RewardSeeder {
  /// ВАЖНО:
  /// Поднимаем версию сида, чтобы новые данные реально начали использоваться.
  /// Старые записи в БД остаются, но репозиторий будет брать только текущую version.
  ///
  /// Текущая версия сида.
  ///
  /// v4: пересобрали ALTAR под новую концепцию:
  /// - редкость = КЛАСС скилла (фиксирована для каждого id)
  /// - у скилла есть maxLevel (обычно 2)
  /// - повторный выбор = повышение level
  /// - после maxLevel скилл будет исключаться из пула ролла (сделаем на шаге 3)
  static const int currentVersion = 4;

  static Future<void> ensureSeeded(AppDatabase db) async {
    // ===== Само-ремонт данных =====
    // levelUp = только статы, поэтому любые бафы оттуда вычищаем.
    await (db.delete(db.rewardDefinitions)
          ..where((t) => t.source.equals('levelUp'))
          ..where((t) => t.kind.equals('buff')))
        .go();

    // Принудительно пересидим текущую версию целиком.
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
      ..._statVariants(
        source: 'levelUp',
        id: 'stat_evasion',
        titleKey: 'upg_evasion_title',
        descKey: 'upg_evasion_desc',
        stat: 'evasion',
        iconKey: 'stat',
        common: 0.02,
        rare: 0.03,
        epic: 0.04,
        legendary: 0.06,
      ),
      ..._statVariants(
        source: 'levelUp',
        id: 'stat_maxMana',
        titleKey: 'upg_mana_title',
        descKey: 'upg_mana_desc',
        stat: 'maxMana',
        iconKey: 'stat',
        common: 15,
        rare: 25,
        epic: 40,
        legendary: 60,
      ),
      ..._statVariants(
        source: 'levelUp',
        id: 'stat_manaRegen',
        titleKey: 'upg_mana_regen_title',
        descKey: 'upg_mana_regen_desc',
        stat: 'manaRegen',
        iconKey: 'stat',
        common: 0.6,
        rare: 0.9,
        epic: 1.2,
        legendary: 1.6,
      ),

      // ===========================
      // CHEST — предметы
      // ===========================
      ..._itemVariants(
        source: 'chest',
        id: 'item_book_hardship',
        titleKey: 'chest_book_hardship_title',
        descKey: 'chest_book_hardship_desc',
        iconKey: 'book',
        paramKey: 'spawnRateAdd',
        common: 0.25,
        rare: 0.40,
        epic: 0.60,
        legendary: 0.85,
      ),
      ..._itemVariantsMap(
        source: 'chest',
        id: 'item_book_chaos',
        titleKey: 'chest_book_chaos_title',
        descKey: 'chest_book_chaos_desc',
        iconKey: 'book',
        common: {
          'spawnRateAdd': 0.20,
          'eliteChanceAdd': 0.06,
          'eliteHpMult': 1.35,
          'eliteDmgMult': 1.20,
          'eliteScoreMult': 1.30,
          'eliteXpMult': 1.20,
        },
        rare: {
          'spawnRateAdd': 0.30,
          'eliteChanceAdd': 0.09,
          'eliteHpMult': 1.45,
          'eliteDmgMult': 1.30,
          'eliteScoreMult': 1.50,
          'eliteXpMult': 1.35,
        },
        epic: {
          'spawnRateAdd': 0.40,
          'eliteChanceAdd': 0.12,
          'eliteHpMult': 1.60,
          'eliteDmgMult': 1.45,
          'eliteScoreMult': 1.70,
          'eliteXpMult': 1.50,
        },
        legendary: {
          'spawnRateAdd': 0.55,
          'eliteChanceAdd': 0.16,
          'eliteHpMult': 1.80,
          'eliteDmgMult': 1.60,
          'eliteScoreMult': 2.00,
          'eliteXpMult': 1.70,
        },
      ),
      ..._itemVariantsMap(
        source: 'chest',
        id: 'item_book_luck',
        titleKey: 'chest_book_luck_title',
        descKey: 'chest_book_luck_desc',
        iconKey: 'book',
        common: {'luckBonusAdd': 0.10, 'maxHpDelta': -6},
        rare: {'luckBonusAdd': 0.18, 'maxHpDelta': -10},
        epic: {'luckBonusAdd': 0.26, 'maxHpDelta': -14},
        legendary: {'luckBonusAdd': 0.35, 'maxHpDelta': -20},
      ),
      ..._itemVariantsMap(
        source: 'chest',
        id: 'item_book_knowledge',
        titleKey: 'chest_book_knowledge_title',
        descKey: 'chest_book_knowledge_desc',
        iconKey: 'book',
        common: {'xpGainMult': 0.20, 'damageDelta': -1},
        rare: {'xpGainMult': 0.35, 'damageDelta': -2},
        epic: {'xpGainMult': 0.50, 'damageDelta': -3},
        legendary: {'xpGainMult': 0.70, 'damageDelta': -5},
      ),

      // ===========================
      // ALTAR — магия (buffs/abilities)
      // ===========================
      // NOTE: теперь у каждого altar-скилла ОДНА фиксированная редкость.
      // Прокачка идёт через level, а не через "легендарную версию".

      // ---- COMMON ----
      _altarSkillRow(
        id: 'buff_freeze_aura',
        rarity: 'common',
        kind: 'buff',
        titleKey: 'altar_freeze_aura_title',
        descKey: 'altar_freeze_aura_desc',
        iconKey: 'snow',
        maxLevel: 4,
        trigger: {
          'kind': 'timer',
          'event': null,
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {'radius': 1.7, 'intervalSec': 6.0, 'freezeSec': 0.8},
          },
          {
            'level': 2,
            'values': {'radius': 2.1, 'intervalSec': 5.0, 'freezeSec': 1.1},
          },
          {
            'level': 3,
            'values': {'radius': 2.4, 'intervalSec': 4.6, 'freezeSec': 1.3},
          },
          {
            'level': 4,
            'values': {'radius': 2.7, 'intervalSec': 4.2, 'freezeSec': 1.5},
          },
        ],
      ),
      _altarSkillRow(
        id: 'buff_ignite_on_hit',
        rarity: 'common',
        kind: 'buff',
        titleKey: 'altar_ignite_title',
        descKey: 'altar_ignite_desc',
        iconKey: 'bolt',
        maxLevel: 4,
        trigger: {
          'kind': 'onHit',
          'event': 'DamageDealtEvent',
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {'procChance': 0.22, 'durationSec': 2.5, 'totalDamagePct': 0.18},
          },
          {
            'level': 2,
            'values': {'procChance': 0.32, 'durationSec': 3.0, 'totalDamagePct': 0.25},
          },
          {
            'level': 3,
            'values': {'procChance': 0.40, 'durationSec': 3.4, 'totalDamagePct': 0.32},
          },
          {
            'level': 4,
            'values': {'procChance': 0.48, 'durationSec': 3.8, 'totalDamagePct': 0.40},
          },
        ],
      ),
      _altarSkillRow(
        id: 'buff_slow_strikes',
        rarity: 'common',
        kind: 'buff',
        titleKey: 'altar_slow_strikes_title',
        descKey: 'altar_slow_strikes_desc',
        iconKey: 'snow',
        maxLevel: 4,
        trigger: {
          'kind': 'onHit',
          'event': 'DamageDealtEvent',
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {'slowPct': 0.20, 'durationSec': 0.7},
          },
          {
            'level': 2,
            'values': {'slowPct': 0.28, 'durationSec': 0.9},
          },
          {
            'level': 3,
            'values': {'slowPct': 0.34, 'durationSec': 1.1},
          },
          {
            'level': 4,
            'values': {'slowPct': 0.40, 'durationSec': 1.3},
          },
        ],
      ),
      _altarSkillRow(
        id: 'buff_thorns',
        rarity: 'common',
        kind: 'buff',
        titleKey: 'altar_thorns_title',
        descKey: 'altar_thorns_desc_v2',
        iconKey: 'shield',
        maxLevel: 4,
        trigger: {
          'kind': 'onPlayerDamaged',
          'event': null,
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {'reflectPct': 0.12},
          },
          {
            'level': 2,
            'values': {'reflectPct': 0.20},
          },
          {
            'level': 3,
            'values': {'reflectPct': 0.28},
          },
          {
            'level': 4,
            'values': {'reflectPct': 0.38},
          },
        ],
      ),

      // ---- RARE ----
      _altarSkillRow(
        id: 'buff_piercing_projectiles',
        rarity: 'rare',
        kind: 'buff',
        titleKey: 'altar_piercing_title',
        descKey: 'altar_piercing_desc',
        iconKey: 'stat',
        maxLevel: 2,
        trigger: {
          'kind': 'passive',
          'event': null,
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {'pierceCount': 1}
          },
          {
            'level': 2,
            'values': {'pierceCount': 2}
          },
        ],
      ),
      _altarSkillRow(
        id: 'buff_ricochet',
        rarity: 'rare',
        kind: 'buff',
        titleKey: 'altar_ricochet_title',
        descKey: 'altar_ricochet_desc',
        iconKey: 'stat',
        maxLevel: 2,
        trigger: {
          'kind': 'passive',
          'event': null,
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {'bounces': 1, 'damageMultiplier': 0.70}
          },
          {
            'level': 2,
            'values': {'bounces': 2, 'damageMultiplier': 0.75}
          },
        ],
      ),
      _altarSkillRow(
        id: 'buff_bleed_on_hit',
        rarity: 'rare',
        kind: 'buff',
        titleKey: 'altar_bleed_title',
        descKey: 'altar_bleed_desc',
        iconKey: 'bolt',
        maxLevel: 2,
        trigger: {
          'kind': 'onHit',
          'event': 'DamageDealtEvent',
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {'procChance': 0.25, 'durationSec': 3.0, 'totalDamagePct': 0.30},
          },
          {
            'level': 2,
            'values': {'procChance': 0.35, 'durationSec': 3.5, 'totalDamagePct': 0.40},
          },
        ],
      ),
      _altarSkillRow(
        id: 'buff_soul_on_kill',
        rarity: 'rare',
        kind: 'buff',
        titleKey: 'altar_soul_on_kill_title',
        descKey: 'altar_soul_on_kill_desc',
        iconKey: 'shield',
        maxLevel: 2,
        trigger: {
          'kind': 'onKill',
          'event': 'EnemyKilledEvent',
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {'procChance': 0.30, 'healPctMaxHp': 0.015}
          },
          {
            'level': 2,
            'values': {'procChance': 0.45, 'healPctMaxHp': 0.022}
          },
        ],
      ),

      // ---- EPIC ----
      _altarSkillRow(
        id: 'buff_chain_lightning',
        rarity: 'epic',
        kind: 'buff',
        titleKey: 'altar_chain_lightning_title',
        descKey: 'altar_chain_lightning_desc',
        iconKey: 'bolt',
        maxLevel: 2,
        trigger: {
          'kind': 'onHit',
          'event': 'DamageDealtEvent',
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        // Для обратной совместимости на этапе рефакторинга:
        // старый код ожидает procChance в корне.
        legacy: const {'procChance': 0.12},
        levels: [
          {
            'level': 1,
            'values': {
              'procChance': 0.12,
              'internalCooldownSec': 0.60,
              'jumps': 3,
              'damagePctOfHit': 0.55,
            },
          },
          {
            'level': 2,
            'values': {
              'procChance': 0.16,
              'internalCooldownSec': 0.50,
              'jumps': 5,
              'damagePctOfHit': 0.65,
            },
          },
        ],
      ),
      _altarSkillRow(
        id: 'buff_nova_burst',
        rarity: 'epic',
        kind: 'buff',
        titleKey: 'altar_nova_burst_title',
        descKey: 'altar_nova_burst_desc',
        iconKey: 'bolt',
        maxLevel: 2,
        trigger: {
          'kind': 'onHit',
          'event': 'DamageDealtEvent',
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {
              'procChance': 0.10,
              'internalCooldownSec': 1.0,
              'radius': 2.2,
              'damagePctOfHit': 0.70
            },
          },
          {
            'level': 2,
            'values': {
              'procChance': 0.14,
              'internalCooldownSec': 0.9,
              'radius': 2.6,
              'damagePctOfHit': 0.85
            },
          },
        ],
      ),
      _altarSkillRow(
        id: 'buff_poison_cloud',
        rarity: 'epic',
        kind: 'buff',
        titleKey: 'altar_poison_cloud_title',
        descKey: 'altar_poison_cloud_desc',
        iconKey: 'bolt',
        maxLevel: 2,
        trigger: {
          'kind': 'aura',
          'event': null,
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {'radius': 2.0, 'tickSec': 0.60, 'damagePctBase': 0.14}
          },
          {
            'level': 2,
            'values': {'radius': 2.4, 'tickSec': 0.55, 'damagePctBase': 0.18}
          },
        ],
      ),
      _altarSkillRow(
        id: 'ability_frost_ring',
        rarity: 'epic',
        kind: 'ability',
        titleKey: 'altar_frost_ring_title',
        descKey: 'altar_frost_ring_desc',
        iconKey: 'snow',
        maxLevel: 2,
        trigger: {
          'kind': 'active',
          'event': null,
          'cooldownSec': 14.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {
              'cooldownSec': 14.0,
              'manaCost': 28.0,
              'radius': 2.6,
              'freezeSec': 1.0,
              'damagePctBase': 0.60
            }
          },
          {
            'level': 2,
            'values': {
              'cooldownSec': 12.0,
              'manaCost': 28.0,
              'radius': 3.0,
              'freezeSec': 1.3,
              'damagePctBase': 0.75
            }
          },
        ],
      ),

      // ---- LEGENDARY ----
      _altarSkillRow(
        id: 'ability_shockwave_stun',
        rarity: 'legendary',
        kind: 'ability',
        titleKey: 'altar_shockwave_title',
        descKey: 'altar_shockwave_desc',
        iconKey: 'bolt',
        maxLevel: 2,
        trigger: {
          'kind': 'active',
          'event': null,
          'cooldownSec': 18.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {
              'cooldownSec': 18.0,
              'manaCost': 32.0,
              'radius': 3.2,
              'stunSec': 1.2,
              'damagePctBase': 0.90
            }
          },
          {
            'level': 2,
            'values': {
              'cooldownSec': 16.0,
              'manaCost': 32.0,
              'radius': 3.6,
              'stunSec': 1.6,
              'damagePctBase': 1.10
            }
          },
        ],
      ),
      _altarSkillRow(
        id: 'buff_tempest_field',
        rarity: 'legendary',
        kind: 'buff',
        titleKey: 'altar_tempest_field_title',
        descKey: 'altar_tempest_field_desc',
        iconKey: 'bolt',
        maxLevel: 2,
        trigger: {
          'kind': 'timer',
          'event': null,
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {'intervalSec': 2.2, 'targets': 2, 'radius': 3.0, 'damagePctBase': 0.85}
          },
          {
            'level': 2,
            'values': {'intervalSec': 2.0, 'targets': 3, 'radius': 3.0, 'damagePctBase': 0.95}
          },
        ],
      ),
      _altarSkillRow(
        id: 'ability_time_dilation',
        rarity: 'legendary',
        kind: 'ability',
        titleKey: 'altar_time_dilation_title',
        descKey: 'altar_time_dilation_desc',
        iconKey: 'snow',
        maxLevel: 2,
        trigger: {
          'kind': 'active',
          'event': null,
          'cooldownSec': 24.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {
              'cooldownSec': 24.0,
              'manaCost': 26.0,
              'radius': 5.0,
              'slowPct': 0.45,
              'durationSec': 2.0
            }
          },
          {
            'level': 2,
            'values': {
              'cooldownSec': 21.0,
              'manaCost': 26.0,
              'radius': 5.0,
              'slowPct': 0.55,
              'durationSec': 2.4
            }
          },
        ],
      ),
      _altarSkillRow(
        id: 'buff_reaper_mark',
        rarity: 'legendary',
        kind: 'buff',
        titleKey: 'altar_reaper_mark_title',
        descKey: 'altar_reaper_mark_desc',
        iconKey: 'bolt',
        maxLevel: 2,
        trigger: {
          'kind': 'onKill',
          'event': 'EnemyKilledEvent',
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        levels: [
          {
            'level': 1,
            'values': {'stacksToExplode': 10, 'radius': 3.2, 'damagePctBase': 2.20}
          },
          {
            'level': 2,
            'values': {'stacksToExplode': 7, 'radius': 3.5, 'damagePctBase': 2.60}
          },
        ],
      ),

      // Вампиризм в новой системе тоже ALTAR-скилл с фиксированной редкостью.
      // Я ставлю его как RARE: это сильная защитная синергия, но не "эпик-магия".
      _altarSkillRow(
        id: 'buff_vampirism',
        rarity: 'rare',
        kind: 'buff',
        titleKey: 'altar_vamp_title',
        descKey: 'altar_vamp_desc',
        iconKey: 'bolt',
        maxLevel: 4,
        trigger: {
          'kind': 'onHit',
          'event': 'DamageDealtEvent',
          'cooldownSec': 0.0,
          'procChance': 0.0,
        },
        // Совместимость со старой логикой _buildDescription + текущим _applyVampirism.
        legacy: const {'lifesteal': 0.03},
        levels: [
          {
            'level': 1,
            'values': {'lifesteal': 0.03}
          },
          {
            'level': 2,
            'values': {'lifesteal': 0.05}
          },
          {
            'level': 3,
            'values': {'lifesteal': 0.07}
          },
          {
            'level': 4,
            'values': {'lifesteal': 0.10}
          },
        ],
      ),

      // ===========================
      // BOSS — уникальные эффекты
      // ===========================
      _row(
        source: 'boss',
        id: 'boss_phoenix_heart',
        kind: 'buff',
        rarity: 'legendary',
        weight: 1,
        titleKey: 'boss_phoenix_heart_title',
        descKey: 'boss_phoenix_heart_desc',
        iconKey: 'bolt',
        params: const {},
      ),
      _row(
        source: 'boss',
        id: 'boss_time_crystal',
        kind: 'buff',
        rarity: 'legendary',
        weight: 1,
        titleKey: 'boss_time_crystal_title',
        descKey: 'boss_time_crystal_desc',
        iconKey: 'bolt',
        params: const {},
      ),
      _row(
        source: 'boss',
        id: 'boss_titan_shield',
        kind: 'buff',
        rarity: 'legendary',
        weight: 1,
        titleKey: 'boss_titan_shield_title',
        descKey: 'boss_titan_shield_desc',
        iconKey: 'shield',
        params: const {},
      ),
      _row(
        source: 'boss',
        id: 'boss_storm_heart',
        kind: 'buff',
        rarity: 'legendary',
        weight: 1,
        titleKey: 'boss_storm_heart_title',
        descKey: 'boss_storm_heart_desc',
        iconKey: 'bolt',
        params: const {},
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

  /// Варианты предмета по редкости.
  static List<RewardDefinitionsCompanion> _itemVariants({
    required String source,
    required String id,
    required String titleKey,
    required String descKey,
    required String iconKey,
    required String paramKey,
    required Object common,
    required Object rare,
    required Object epic,
    required Object legendary,
    double weight = 1,
  }) {
    return [
      _row(
        source: source,
        id: id,
        kind: 'item',
        rarity: 'common',
        weight: weight,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: {paramKey: common},
      ),
      _row(
        source: source,
        id: id,
        kind: 'item',
        rarity: 'rare',
        weight: weight,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: {paramKey: rare},
      ),
      _row(
        source: source,
        id: id,
        kind: 'item',
        rarity: 'epic',
        weight: weight,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: {paramKey: epic},
      ),
      _row(
        source: source,
        id: id,
        kind: 'item',
        rarity: 'legendary',
        weight: weight,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: {paramKey: legendary},
      ),
    ];
  }

  static List<RewardDefinitionsCompanion> _itemVariantsMap({
    required String source,
    required String id,
    required String titleKey,
    required String descKey,
    required String iconKey,
    required Map<String, Object?> common,
    required Map<String, Object?> rare,
    required Map<String, Object?> epic,
    required Map<String, Object?> legendary,
    double weight = 1,
  }) {
    return [
      _row(
        source: source,
        id: id,
        kind: 'item',
        rarity: 'common',
        weight: weight,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: common,
      ),
      _row(
        source: source,
        id: id,
        kind: 'item',
        rarity: 'rare',
        weight: weight,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: rare,
      ),
      _row(
        source: source,
        id: id,
        kind: 'item',
        rarity: 'epic',
        weight: weight,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: epic,
      ),
      _row(
        source: source,
        id: id,
        kind: 'item',
        rarity: 'legendary',
        weight: weight,
        titleKey: titleKey,
        descKey: descKey,
        iconKey: iconKey,
        params: legendary,
      ),
    ];
  }

  /// Строка для ALTAR-скиллов новой системы.
  ///
  /// Важно:
  /// - `rarity` фиксирована и определяет КЛАСС скилла.
  /// - прокачка — через `level`, поэтому в paramsJson лежит массив `levels`.
  /// - `legacy` — необязательный блок для обратной совместимости,
  ///   пока мы по шагам переписываем RewardRepository / UpgradeRegistry.
  static RewardDefinitionsCompanion _altarSkillRow({
    required String id,
    required String rarity,
    required String kind,
    required String titleKey,
    required String descKey,
    required String iconKey,
    required int maxLevel,
    required Map<String, Object?> trigger,
    required List<Map<String, Object?>> levels,
    Map<String, Object?> legacy = const <String, Object?>{},
    double weight = 1,
  }) {
    // Единый формат paramsJson для алтарей.
    final params = <String, Object?>{
      'maxLevel': maxLevel,
      'trigger': trigger,
      'levels': levels,
    };

    // Если есть обратная совместимость — добавляем плоские ключи.
    // Например: lifesteal / procChance.
    if (legacy.isNotEmpty) {
      params.addAll(legacy);
      params['legacy'] = legacy;
    }

    return _row(
      source: 'altar',
      id: id,
      kind: kind,
      rarity: rarity,
      weight: weight,
      titleKey: titleKey,
      descKey: descKey,
      iconKey: iconKey,
      params: params,
    );
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
