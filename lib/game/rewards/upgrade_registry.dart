import 'dart:convert';
import 'dart:math';

import 'package:pixel_clash/game/components/combat/buffs/altar_buffs.dart';
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
      'stat_evasion': _applyStat,

      // ===== buffs =====
      'buff_chain_lightning': _applyChainLightning,
      'buff_vampirism': _applyVampirism,
      'buff_freeze_aura': _applyFreezeAura,
      'buff_ignite_on_hit': _applyIgniteOnHit,
      'buff_slow_strikes': _applySlowStrikes,
      'buff_thorns': _applyThorns,
      'buff_piercing_projectiles': _applyPiercingProjectiles,
      'buff_ricochet': _applyRicochet,
      'buff_bleed_on_hit': _applyBleedOnHit,
      'buff_soul_on_kill': _applySoulOnKill,
      'buff_nova_burst': _applyNovaBurst,
      'buff_poison_cloud': _applyPoisonCloud,
      'buff_tempest_field': _applyTempestField,
      'buff_reaper_mark': _applyReaperMark,

      // ===== abilities =====
      'ability_frost_ring': _applyFrostRing,
      'ability_shockwave_stun': _applyShockwaveStun,
      'ability_time_dilation': _applyTimeDilation,

      // ===== items =====
      'item_book_hardship': _applyBookHardship,

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
      case 'evasion':
        p.stats.evasionChance = (p.stats.evasionChance + delta).clamp(0.0, 0.80);
        break;
      case 'maxMana':
        p.stats.maxMana += delta;
        p.stats.mana = (p.stats.mana + delta).clamp(0, p.stats.maxMana);
        break;
      case 'manaRegen':
        p.stats.manaRegen += delta;
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

  // ===== altar skills =====

  void _applyFreezeAura(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      FreezeAuraBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyIgniteOnHit(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      IgniteOnHitBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applySlowStrikes(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      SlowStrikesBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyThorns(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      ThornsBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyPiercingProjectiles(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      PiercingProjectilesBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyRicochet(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      RicochetBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyBleedOnHit(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      BleedOnHitBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applySoulOnKill(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      SoulOnKillBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyNovaBurst(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      NovaBurstBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyPoisonCloud(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      PoisonCloudBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyTempestField(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      TempestFieldBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyReaperMark(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      ReaperMarkBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyFrostRing(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      FrostRingAbility(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
    game.assignAbilitySlot('ability_frost_ring');
  }

  void _applyShockwaveStun(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      ShockwaveStunAbility(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
    game.assignAbilitySlot('ability_shockwave_stun');
  }

  void _applyTimeDilation(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      TimeDilationAbility(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
    game.assignAbilitySlot('ability_time_dilation');
  }

  int _maxLevelFromParams(Map<String, Object?> params) {
    final raw = params['maxLevel'];
    if (raw is num) return max(1, raw.toInt());
    return 1;
  }

  Map<int, Map<String, Object?>> _levelsFromParams(Map<String, Object?> params) {
    final raw = params['levels'];
    final result = <int, Map<String, Object?>>{};

    if (raw is List) {
      for (final e in raw) {
        if (e is! Map) continue;
        final levelRaw = e['level'];
        final valuesRaw = e['values'];
        if (levelRaw is! num || valuesRaw is! Map) continue;
        final level = levelRaw.toInt();
        final values = <String, Object?>{};
        for (final entry in valuesRaw.entries) {
          final k = entry.key;
          if (k is String) values[k] = entry.value;
        }
        result[level] = values;
      }
    }

    return result;
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
