import 'dart:convert';
import 'dart:math';

import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/data/app_database.dart';
import 'package:pixel_clash/game/data/reward_seeder.dart';
import 'package:pixel_clash/game/localization/l10n.dart';
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
  }) async {
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
      if (r.id.trim().isEmpty) return false;
      if (r.titleKey.trim().isEmpty) return false;
      if (r.descKey.trim().isEmpty) return false;
      if (r.kind.trim().isEmpty) return false;
      if (r.rarity.trim().isEmpty) return false;
      return true;
    }).toList();

    if (rows.isEmpty) return <RewardDefinition>[];

    final usedIds = <String>{};
    final result = <RewardDefinition>[];

    for (var i = 0; i < count; i++) {
      final rolledRarity = _rollRarityForSource(rng, source);

      final byRarity =
          rows.where((r) => r.rarity == rolledRarity.name && !usedIds.contains(r.id)).toList();

      // Если по редкости ничего нет, берём из любого, но тоже без повторов по id
      final picked = _weightedPick(rng, byRarity) ??
          _weightedPick(rng, rows.where((r) => !usedIds.contains(r.id)).toList());

      if (picked == null) break;

      usedIds.add(picked.id);

      final rarity = _rarityFromString(picked.rarity);
      final params = _decodeParams(picked.paramsJson);
      final desc = _buildDescription(l10n, picked.descKey, picked.id, params);

      result.add(
        RewardDefinition(
          id: picked.id,
          source: source,
          kind: _kindFromString(picked.kind),
          rarity: rarity,
          title: l10n.t(picked.titleKey),
          description: desc,
          icon: icons.iconByKey(picked.iconKey),
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

  Rarity _rollRarityForSource(Random rng, RewardSource source) {
    final (commonW, rareW, epicW, legendaryW) = switch (source) {
      RewardSource.levelUp => (70.0, 22.0, 7.0, 1.0),
      RewardSource.chest => (55.0, 30.0, 12.0, 3.0),
      RewardSource.altar => (45.0, 35.0, 16.0, 4.0),
      RewardSource.vendor => (60.0, 28.0, 10.0, 2.0),
    };

    final total = commonW + rareW + epicW + legendaryW;
    final x = rng.nextDouble() * total;

    var acc = commonW;
    if (x < acc) return Rarity.common;

    acc += rareW;
    if (x < acc) return Rarity.rare;

    acc += epicW;
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

  String _buildDescription(L10n l10n, String descKey, String id, Map<String, Object?> params) {
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
      if (stat == 'manaRegen') {
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
}
