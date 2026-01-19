import 'dart:convert';

import 'package:pixel_clash/game/components/combat/buffs/chain_lightning_buff.dart';
import 'package:pixel_clash/game/components/combat/buffs/vampirism_buff.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/rewards/player_build_state.dart';

typedef RewardHandler = void Function(
  PixelClashGame game,
  Map<String, Object?> params,
  PlayerBuildState build,
  Rarity rarity,
);

class UpgradeRegistry {
  UpgradeRegistry() {
    _handlers = <String, RewardHandler>{
      // ===== stats =====
      'stat_damage': _applyStat,
      'stat_attackSpeed': _applyStat,
      'stat_armor': _applyStat,
      'stat_hp': _applyStat,
      'stat_critChance': _applyStat,
      'stat_moveSpeed': _applyStat,

      // ===== buffs =====
      'buff_chain_lightning': _applyChainLightning,
      'buff_vampirism': _applyVampirism,

      // ===== items =====
      'item_book_hardship': _applyBookHardship,

      // stubs:
      'buff_freeze_stub': (_, __, ___, ____) {},
      'buff_thorns_stub': (_, __, ___, ____) {},
    };
  }

  late final Map<String, RewardHandler> _handlers;

  void apply({
    required String id,
    required String paramsJson,
    required Rarity rarity,
    required PixelClashGame game,
    required PlayerBuildState build,
  }) {
    final handler = _handlers[id];
    if (handler == null) return;

    final params = _decodeParams(paramsJson);

    // стеки считаем централизованно:
    build.addStack(id, delta: 1);

    handler(game, params, build, rarity);
  }

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

  // ==========================
  // Handlers
  // ==========================

  void _applyStat(
      PixelClashGame game, Map<String, Object?> params, PlayerBuildState build, Rarity rarity) {
    final p = game.player;
    if (p == null) return;

    final stat = params['stat'];
    final deltaRaw = params['delta'];

    if (stat is! String || deltaRaw is! num) return;

    final delta = deltaRaw.toDouble();

    switch (stat) {
      case 'damage':
        p.stats.damage += delta.round();
        break;

      case 'attackSpeed':
        p.stats.attackSpeed += delta;
        break;

      case 'armor':
        p.stats.armor += delta.round();
        break;

      case 'hp':
        final add = delta.round();
        p.stats.maxHp += add;
        p.stats.heal(add);
        break;

      case 'critChance':
        p.stats.critChance = (p.stats.critChance + delta).clamp(0.0, 0.80);
        break;

      case 'moveSpeed':
        p.stats.moveSpeed += delta;
        break;
    }

    // обновляем HUD (hp/maxHp/armor)
    game.notifyPlayerStatsChanged();
  }

  void _applyChainLightning(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;

    p.buffs.addBuff(ChainLightningBuff(rarity: rarity));
  }

  void _applyVampirism(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;

    final ls = params['lifesteal'];
    final base = (ls is num) ? ls.toDouble() : 0.03;

    p.buffs.addBuff(VampirismBuff(rarity: rarity, baseLifesteal: base));
  }

  void _applyBookHardship(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final add = params['spawnRateAdd'];
    if (add is! num) return;

    // Суммируем прибавку (аддитивно).
    // Например common +25% и rare +40% => итого +65% частоты спавна.
    game.runModifiers.enemySpawnRateAdd += add.toDouble();
  }
}
