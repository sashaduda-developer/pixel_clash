import 'dart:convert';
import 'dart:math';

import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/data/app_database.dart';
import 'package:pixel_clash/game/data/reward_seeder.dart';
import 'package:pixel_clash/game/localization/l10n.dart';
import 'package:pixel_clash/game/components/player/hero_type.dart';
import 'package:pixel_clash/game/rewards/icon_registry.dart';
import 'package:pixel_clash/game/rewards/player_build_state.dart';
import 'package:pixel_clash/game/rewards/reward_definition.dart';
import 'package:pixel_clash/game/rewards/upgrade_registry.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

class RewardRepository {
  RewardRepository({
    required this.db,
    required this.registry,
    required this.icons,
  });

  final AppDatabase db;
  final UpgradeRegistry registry;
  final IconRegistry icons;

  Future<List<RewardDefinition>> roll({
    required RewardSource source,
    required int count,
    required Random rng,
    required L10n l10n,
    required PixelClashGame game,
    required PlayerBuildState build,
    double luckBonus = 0.0,
    Set<String>? excludeIds,
    Rarity? minRarity,
    RewardKind? requiredKind,
    Rarity? requiredRarity,
  }) async {
    final excluded = excludeIds ?? const <String>{};
    final requiredKindName = requiredKind?.name;
    final requiredRarityName = requiredRarity?.name;
    // 1) Пытаемся взять строки текущей версии.
    var rows = await _loadRows(source: source, version: RewardSeeder.currentVersion);

    // 2) Если текущей версии нет (часто бывает после правок сидера/версий),
    // берём ПОСЛЕДНЮЮ доступную версию для этого source.
    if (rows.isEmpty) {
      final latest = await _latestVersionForSource(source);
      if (latest != null && latest != RewardSeeder.currentVersion) {
        rows = await _loadRows(source: source, version: latest);
      }
    }

    // 3) Доп. защита от мусорных строк (пустые ключи и т.п.)
    rows = rows.where((r) {
      if (excluded.contains(r.id)) return false;
      if (requiredKindName != null && r.kind != requiredKindName) return false;
      if (requiredRarityName != null && r.rarity != requiredRarityName) return false;
      if (r.id.trim().isEmpty) return false;
      if (r.titleKey.trim().isEmpty) return false;
      if (r.descKey.trim().isEmpty) return false;
      if (r.kind.trim().isEmpty) return false;
      if (r.rarity.trim().isEmpty) return false;
      return true;
    }).toList();

    if (source == RewardSource.altar) {
      final heroKey = _heroKey(game.player?.heroType);
      if (heroKey != null) {
        rows = rows.where((r) => _matchesHero(r, heroKey)).toList();
      }
    }

    if (rows.isEmpty) return <RewardDefinition>[];

    final usedIds = <String>{};
    final result = <RewardDefinition>[];

    for (var i = 0; i < count; i++) {
      var rolledRarity = requiredRarity ?? _rollRarityForSource(rng, source, luckBonus);
      if (requiredRarity == null && minRarity != null && rolledRarity.index < minRarity.index) {
        rolledRarity = minRarity;
      }

      final byRarity = rows.where((r) {
        if (r.rarity != rolledRarity.name) return false;
        if (usedIds.contains(r.id)) return false;
        if (_isMaxed(r.id, r.paramsJson, build)) return false;
        return true;
      }).toList();

      // Если по редкости ничего нет, берём из любого, но тоже без повторов по id
      final picked = _weightedPick(rng, byRarity) ??
          _weightedPick(rng, rows.where((r) => !usedIds.contains(r.id) && !_isMaxed(r.id, r.paramsJson, build)).toList());

      if (picked == null) break;

      usedIds.add(picked.id);

      final rarity = _rarityFromString(picked.rarity);
      final params = _decodeParams(picked.paramsJson);
      final desc = _buildDescription(l10n, picked.descKey, picked.id, params, build);

      // Уровни нужны только для алтарных скиллов (maxLevel в params).
      final maxLevel = _maxLevelFromParams(params);
      final kind = _kindFromString(picked.kind);
      final levelInfo = _levelInfoForReward(
        id: picked.id,
        maxLevel: maxLevel,
        build: build,
      );
      final stats = _buildStatsForReward(kind, params, levelInfo?.nextLevel);

      result.add(
        RewardDefinition(
          id: picked.id,
          source: source,
          kind: kind,
          rarity: rarity,
          title: l10n.t(picked.titleKey),
          description: desc,
          icon: icons.iconByKey(picked.iconKey),
          stats: stats,
          currentLevel: levelInfo?.currentLevel,
          nextLevel: levelInfo?.nextLevel,
          maxLevel: levelInfo?.maxLevel,
          apply: (_) {
            registry.apply(
              id: picked.id,
              paramsJson: picked.paramsJson,
              rarity: rarity,
              game: game,
              build: build,
            );
          },
        ),
      );
    }

    return result;
  }

  // ==========================
  // DB helpers
  // ==========================

  Future<List<RewardDbRow>> _loadRows({
    required RewardSource source,
    required int version,
  }) async {
    return (db.select(db.rewardDefinitions)
          ..where((t) => t.source.equals(source.name))
          ..where((t) => t.version.equals(version)))
        .get();
  }

  Future<int?> _latestVersionForSource(RewardSource source) async {
    // Берём все версии по source и выбираем max.
    final rows = await (db.selectOnly(db.rewardDefinitions)
          ..addColumns([db.rewardDefinitions.version])
          ..where(db.rewardDefinitions.source.equals(source.name)))
        .get();

    var best = -1;
    for (final r in rows) {
      final v = r.read(db.rewardDefinitions.version);
      if (v != null && v > best) best = v;
    }
    return best >= 0 ? best : null;
  }

  // ==========================
  // Rarity roll / mapping
  // ==========================

  Rarity _rollRarityForSource(Random rng, RewardSource source, double luckBonus) {
    final (commonW, rareW, epicW, legendaryW) = switch (source) {
      RewardSource.levelUp => (70.0, 22.0, 7.0, 1.0),
      RewardSource.chest => (55.0, 30.0, 12.0, 3.0),
      RewardSource.altar => (45.0, 35.0, 16.0, 4.0),
      RewardSource.boss => (0.0, 0.0, 0.0, 1.0),
      RewardSource.vendor => (60.0, 28.0, 10.0, 2.0),
    };

    final luck = luckBonus.clamp(0.0, 0.8);
    final commonAdj = max(1.0, commonW * (1.0 - luck * 0.6));
    final rareAdj = rareW * (1.0 + luck * 0.8);
    final epicAdj = epicW * (1.0 + luck * 0.6);
    final legendaryAdj = legendaryW * (1.0 + luck * 0.4);

    final total = commonAdj + rareAdj + epicAdj + legendaryAdj;
    final x = rng.nextDouble() * total;

    var acc = commonAdj;
    if (x < acc) return Rarity.common;

    acc += rareAdj;
    if (x < acc) return Rarity.rare;

    acc += epicAdj;
    if (x < acc) return Rarity.epic;

    return Rarity.legendary;
  }

  RewardKind _kindFromString(String s) {
    return switch (s) {
      'buff' => RewardKind.buff,
      'ability' => RewardKind.ability,
      'item' => RewardKind.item,
      _ => RewardKind.stat,
    };
  }

  Rarity _rarityFromString(String s) {
    return switch (s) {
      'rare' => Rarity.rare,
      'epic' => Rarity.epic,
      'legendary' => Rarity.legendary,
      _ => Rarity.common,
    };
  }

  RewardDbRow? _weightedPick(Random rng, List<RewardDbRow> list) {
    if (list.isEmpty) return null;

    var total = 0.0;
    for (final r in list) {
      total += max(0.0, r.weight);
    }
    if (total <= 0) return list[rng.nextInt(list.length)];

    var roll = rng.nextDouble() * total;
    for (final r in list) {
      roll -= max(0.0, r.weight);
      if (roll <= 0) return r;
    }
    return list.last;
  }

  // ==========================
  // params / description
  // ==========================

  Map<String, Object?> _decodeParams(String s) {
    try {
      final v = jsonDecode(s);
      if (v is Map<String, dynamic>) {
        return v.map((k, v) => MapEntry(k, v));
      }
      return const <String, Object?>{};
    } catch (_) {
      return const <String, Object?>{};
    }
  }

  String _buildDescription(
    L10n l10n,
    String descKey,
    String id,
    Map<String, Object?> params,
    PlayerBuildState build,
  ) {
    final delta = params['delta'];
    if (delta is num) {
      final stat = params['stat'];
      if (stat == 'critChance' || stat == 'evasion') {
        final pct = (delta.toDouble() * 100).round();
        return l10n.tParams(descKey, {'value': '$pct'});
      }
      if (stat == 'attackSpeed') {
        return l10n.tParams(descKey, {'value': delta.toStringAsFixed(2)});
      }
      if (stat == 'manaRegen' || stat == 'hpRegen') {
        return l10n.tParams(descKey, {'value': delta.toStringAsFixed(1)});
      }
      return l10n.tParams(descKey, {'value': '${delta.round()}'}); 
    }

    final ls = params['lifesteal'];
    if (ls is num) {
      final pct = (ls.toDouble() * 100).round();
      return l10n.tParams(descKey, {'value': '$pct'});
    }

    final spawn = params['spawnRateAdd'];
    if (spawn is num) {
      final pct = (spawn.toDouble() * 100).round();
      return l10n.tParams(descKey, {'value': '$pct'});
    }

    return l10n.t(descKey);
  }

  String? _heroKey(HeroType? type) {
    if (type == null) return null;
    return switch (type) {
      HeroType.ranger => 'ranger',
      HeroType.knight => 'knight',
      HeroType.mage => 'mage',
      HeroType.ninja => 'ninja',
    };
  }

  bool _matchesHero(RewardDbRow row, String heroKey) {
    final params = _decodeParams(row.paramsJson);
    final hero = params['hero'];
    if (hero == null) return true;
    if (hero is! String) return false;
    return hero == heroKey;
  }

  int? _maxLevelFromParams(Map<String, Object?> params) {
    final raw = params['maxLevel'];
    if (raw is! num) return null;
    final v = raw.toInt();
    if (v <= 1) return null;
    return v;
  }

  _LevelInfo? _levelInfoForReward({
    required String id,
    required int? maxLevel,
    required PlayerBuildState build,
  }) {
    if (maxLevel == null) return null;
    // Текущий уровень = сколько раз уже выбирали награду.
    final cur = build.getStacks(id);
    final next = (cur + 1).clamp(1, maxLevel);
    return _LevelInfo(
      currentLevel: cur,
      nextLevel: next,
      maxLevel: maxLevel,
    );
  }

  List<RewardStat>? _buildLevelStats(Map<String, Object?> params, int? level) {
    if (level == null) return null;

    final raw = params['levels'];
    if (raw is! List) return null;

    Map<String, Object?>? values;
    for (final e in raw) {
      if (e is! Map) continue;
      final levelRaw = e['level'];
      final valuesRaw = e['values'];
      if (levelRaw is! num || valuesRaw is! Map) continue;
      if (levelRaw.toInt() != level) continue;

      final map = <String, Object?>{};
      for (final entry in valuesRaw.entries) {
        final k = entry.key;
        if (k is String) map[k] = entry.value;
      }
      values = map;
      break;
    }
    if (values == null || values.isEmpty) return null;

    final parts = <RewardStat>[];
    for (final entry in values.entries) {
      final label = _labelForLevelKey(entry.key);
      if (label == null) continue;
      final formatted = _formatLevelValue(entry.key, entry.value);
      if (formatted == null) continue;
      parts.add(
        RewardStat(
          label: label,
          value: formatted,
          polarity: _polarityForKeyValue(entry.key, entry.value),
        ),
      );
    }

    return parts.isEmpty ? null : parts;
  }

  List<RewardStat>? _buildItemStats(Map<String, Object?> params) {
    final parts = <RewardStat>[];

    for (final entry in params.entries) {
      final label = _labelForItemKey(entry.key);
      if (label == null) continue;
      final formatted = _formatItemValue(entry.key, entry.value);
      if (formatted == null) continue;
      parts.add(
        RewardStat(
          label: label,
          value: formatted,
          polarity: _polarityForKeyValue(entry.key, entry.value),
        ),
      );
    }

    return parts.isEmpty ? null : parts;
  }

  List<RewardStat>? _buildStatsForReward(
    RewardKind kind,
    Map<String, Object?> params,
    int? level,
  ) {
    switch (kind) {
      case RewardKind.ability:
      case RewardKind.buff:
        return _buildLevelStats(params, level);
      case RewardKind.item:
        return _buildItemStats(params);
      case RewardKind.stat:
        return null;
    }
  }

  String? _labelForItemKey(String key) {
    return switch (key) {
      'spawnRateAdd' => 'Спавн',
      'eliteChanceAdd' => 'Шанс элитных',
      'eliteHpMult' => 'HP элитных',
      'eliteDmgMult' => 'Урон элитных',
      'eliteScoreMult' => 'Очки элитных',
      'eliteXpMult' => 'XP элитных',
      'luckBonusAdd' => 'Удача',
      'lifestealAdd' => 'Вампиризм',
      'critChanceAdd' => 'Крит шанс',
      'bossDamageMult' => 'Урон по боссам',
      'moveSpeedPct' => 'Скорость',
      'armorPct' => 'Броня',
      'armorDelta' => 'Броня',
      'attackSpeedPct' => 'Скорость атаки',
      'maxManaPct' => 'Макс мана',
      'maxHpPct' => 'Макс HP',
      'reflectPct' => 'Отражение',
      'healMultiplier' => 'Исцеление',
      'maxHpDelta' => 'Макс HP',
      'damageDelta' => 'Урон',
      'xpGainMult' => 'XP',
      _ => null,
    };
  }

  String? _formatItemValue(String key, Object? value) {
    if (value is! num) return null;
    final v = value.toDouble();

    switch (key) {
      case 'spawnRateAdd':
      case 'eliteChanceAdd':
      case 'eliteXpMult':
      case 'luckBonusAdd':
      case 'lifestealAdd':
      case 'critChanceAdd':
      case 'moveSpeedPct':
      case 'attackSpeedPct':
      case 'reflectPct':
        return '${(v * 100).round()}%';
      case 'armorPct':
      case 'maxManaPct':
      case 'maxHpPct':
        return '-${(v * 100).round()}%';
      case 'bossDamageMult':
      case 'healMultiplier':
        final pct = ((v - 1) * 100).round();
        return pct >= 0 ? '+$pct%' : '$pct%';
      case 'xpGainMult':
        return '+${(v * 100).round()}%';
      case 'eliteHpMult':
      case 'eliteDmgMult':
      case 'eliteScoreMult':
        return 'x${v.toStringAsFixed(2)}';
      case 'maxHpDelta':
      case 'damageDelta':
      case 'armorDelta':
        return v >= 0 ? '+${v.round()}' : '${v.round()}';
    }

    return v.toStringAsFixed(2);
  }

  RewardStatPolarity _polarityForKeyValue(String key, Object? value) {
    final v = (value is num) ? value.toDouble() : 0.0;

    switch (key) {
      case 'spawnRateAdd':
      case 'eliteChanceAdd':
      case 'eliteHpMult':
      case 'eliteDmgMult':
        return RewardStatPolarity.negative;
      case 'eliteScoreMult':
      case 'eliteXpMult':
      case 'luckBonusAdd':
      case 'xpGainMult':
      case 'lifestealAdd':
      case 'critChanceAdd':
      case 'moveSpeedPct':
      case 'attackSpeedPct':
      case 'reflectPct':
        return RewardStatPolarity.positive;
      case 'maxHpDelta':
      case 'damageDelta':
      case 'armorDelta':
        return v < 0 ? RewardStatPolarity.negative : RewardStatPolarity.positive;
      case 'armorPct':
      case 'maxManaPct':
      case 'maxHpPct':
        return RewardStatPolarity.negative;
      case 'bossDamageMult':
      case 'healMultiplier':
        if (v < 1) return RewardStatPolarity.negative;
        if (v > 1) return RewardStatPolarity.positive;
        return RewardStatPolarity.neutral;
      case 'manaCost':
        return RewardStatPolarity.negative;
      case 'damageMultiplier':
        if (v > 1) return RewardStatPolarity.positive;
        if (v < 1) return RewardStatPolarity.negative;
        return RewardStatPolarity.neutral;
      case 'thirdHitChance':
      case 'thirdHitDamageMultiplier':
      case 'critBonusMultiplier':
        return RewardStatPolarity.positive;
      case 'hitsToStun':
        return RewardStatPolarity.neutral;
      case 'cooldownSec':
      case 'internalCooldownSec':
      case 'intervalSec':
      case 'tickSec':
        return RewardStatPolarity.neutral;
      default:
        if (v > 0) return RewardStatPolarity.positive;
        if (v < 0) return RewardStatPolarity.negative;
        return RewardStatPolarity.neutral;
    }
  }

  bool _isMaxed(String id, String paramsJson, PlayerBuildState build) {
    final params = _decodeParams(paramsJson);
    final maxLevel = _maxLevelFromParams(params);
    if (maxLevel == null) return false;
    return build.getStacks(id) >= maxLevel;
  }

  String? _labelForLevelKey(String key) {
    return switch (key) {
      'procChance' => 'Шанс',
      'durationSec' => 'Длительность',
      'cooldownSec' => 'КД',
      'manaCost' => 'Мана',
      'totalDamagePct' => 'Урон',
      'damagePctOfHit' => 'Урон',
      'damagePctBase' => 'Урон',
      'radius' => 'Радиус',
      'intervalSec' => 'Интервал',
      'freezeSec' => 'Заморозка',
      'slowPct' => 'Замедление',
      'stunSec' => 'Стан',
      'tickSec' => 'Тик',
      'targets' => 'Цели',
      'jumps' => 'Прыжки',
      'internalCooldownSec' => 'КД',
      'lifesteal' => 'Вампиризм',
      'reflectPct' => 'Отражение',
      'pierceCount' => 'Пробитие',
      'bounces' => 'Рикошеты',
      'damageMultiplier' => 'Множитель',
      'healPctMaxHp' => 'Хил',
      'stacksToExplode' => 'Стаки',
      'thirdHitChance' => 'Шанс 3-го удара',
      'thirdHitDamageMultiplier' => 'Урон 3-го',
      'critBonusMultiplier' => 'Усиление крита',
      'hitsToStun' => 'Удары до стана',
      _ => null,
    };
  }

  String? _formatLevelValue(String key, Object? value) {
    if (value is! num) return null;
    final v = value.toDouble();

    switch (key) {
      case 'procChance':
      case 'reflectPct':
      case 'totalDamagePct':
      case 'damagePctOfHit':
      case 'damagePctBase':
      case 'slowPct':
      case 'lifesteal':
      case 'damageMultiplier':
      case 'healPctMaxHp':
      case 'thirdHitChance':
      case 'thirdHitDamageMultiplier':
      case 'critBonusMultiplier':
        return '${(v * 100).round()}%';
      case 'radius':
        return '${v.toStringAsFixed(1)}м';
      case 'intervalSec':
      case 'durationSec':
      case 'freezeSec':
      case 'stunSec':
      case 'tickSec':
      case 'internalCooldownSec':
        return '${v.toStringAsFixed(1)}с';
      case 'manaCost':
        return '${v.round()}';
      case 'jumps':
      case 'targets':
      case 'stacksToExplode':
      case 'pierceCount':
      case 'bounces':
      case 'hitsToStun':
        return '${v.round()}';
    }

    return v.toStringAsFixed(2);
  }
}

class _LevelInfo {
  _LevelInfo({
    required this.currentLevel,
    required this.nextLevel,
    required this.maxLevel,
  });

  final int currentLevel;
  final int nextLevel;
  final int maxLevel;
}
