import 'dart:convert';
import 'dart:math';

import 'package:pixel_clash/game/components/combat/buffs/altar_buffs.dart';
import 'package:pixel_clash/game/components/combat/buffs/chain_lightning_buff.dart';
import 'package:pixel_clash/game/components/combat/buffs/boss/phoenix_heart_buff.dart';
import 'package:pixel_clash/game/components/combat/buffs/boss/storm_heart_buff.dart';
import 'package:pixel_clash/game/components/combat/buffs/boss/time_crystal_buff.dart';
import 'package:pixel_clash/game/components/combat/buffs/boss/titan_shield_buff.dart';
import 'package:pixel_clash/game/components/combat/buffs/items/necromancer_ring_buff.dart';
import 'package:pixel_clash/game/components/combat/buffs/items/pain_mirror_buff.dart';
import 'package:pixel_clash/game/components/combat/buffs/vampirism_buff.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
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
      'stat_maxMana': _applyStat,
      'stat_manaRegen': _applyStat,
      'stat_hpRegen': _applyStat,
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
      'buff_mage_fire_sphere': _applyMageFireSphere,
      'buff_mage_mana_surge': _applyMageManaSurge,
      'buff_ninja_triple_strike': _applyNinjaTripleStrike,
      'buff_ninja_evasion_strike': _applyNinjaEvasionStrike,
      'buff_knight_wave_pierce': _applyKnightWavePierce,
      'buff_knight_crushing_stun': _applyKnightCrushingStun,
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
      'item_book_chaos': _applyBookChaos,
      'item_book_luck': _applyBookLuck,
      'item_book_knowledge': _applyBookKnowledge,
      'item_ring_necromancer': _applyRingNecromancer,
      'item_mask_hunter': _applyHunterMask,
      'item_boots_panic': _applyPanicBoots,
      'item_amulet_mercury': _applyMercuryAmulet,
      'item_pain_mirror': _applyPainMirror,
      // ===== boss unique =====
      'boss_phoenix_heart': _applyPhoenixHeart,
      'boss_time_crystal': _applyTimeCrystal,
      'boss_titan_shield': _applyTitanShield,
      'boss_storm_heart': _applyStormHeart,

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
      case 'hpRegen':
        p.stats.hpRegen += delta;
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

  void _applyMageFireSphere(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      MageFireSphereBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyMageManaSurge(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      MageManaSurgeBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyNinjaTripleStrike(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      NinjaTripleStrikeBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyNinjaEvasionStrike(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      NinjaEvasionStrikeBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyKnightWavePierce(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      KnightWavePierceBuff(
        rarity: rarity,
        maxLevel: _maxLevelFromParams(params),
        levels: _levelsFromParams(params),
      ),
    );
  }

  void _applyKnightCrushingStun(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(
      KnightCrushingStunBuff(
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

  void _applyBookChaos(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final spawn = params['spawnRateAdd'];
    final eliteChance = params['eliteChanceAdd'];
    final eliteHp = params['eliteHpMult'];
    final eliteDmg = params['eliteDmgMult'];
    final eliteScore = params['eliteScoreMult'];
    final eliteXp = params['eliteXpMult'];

    if (spawn is num) game.runModifiers.enemySpawnRateAdd += spawn.toDouble();
    if (eliteChance is num) game.runModifiers.eliteChanceAdd += eliteChance.toDouble();
    if (eliteHp is num) game.runModifiers.eliteHpMultiplier *= eliteHp.toDouble();
    if (eliteDmg is num) game.runModifiers.eliteDmgMultiplier *= eliteDmg.toDouble();
    if (eliteScore is num) game.runModifiers.eliteScoreMultiplier *= eliteScore.toDouble();
    if (eliteXp is num) game.runModifiers.eliteXpMultiplier *= eliteXp.toDouble();
  }

  void _applyBookLuck(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final luck = params['luckBonusAdd'];
    final hpDelta = params['maxHpDelta'];
    final armorDelta = params['armorDelta'];

    if (luck is num) {
      final add = luck.toDouble();
      game.runModifiers.luckBonusLevelUpAdd += add;
      game.runModifiers.luckBonusAltarAdd += add;
    }

    final p = game.player;
    if (p == null) return;
    if (hpDelta is num) {
      _applyMaxHpDelta(p, hpDelta.round());
      game.notifyPlayerStatsChanged();
      return;
    }
    if (armorDelta is num) {
      p.stats.armor = max(0, p.stats.armor + armorDelta.round());
    }
    game.notifyPlayerStatsChanged();
  }

  void _applyBookKnowledge(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final xp = params['xpGainMult'];
    final dmgDelta = params['damageDelta'];

    if (xp is num) game.runModifiers.xpGainAdd += xp.toDouble();

    final p = game.player;
    if (p == null) return;
    if (dmgDelta is num) {
      p.stats.damage = max(1, p.stats.damage + dmgDelta.round());
    }
  }

  void _applyRingNecromancer(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;

    final ls = params['lifestealAdd'];
    if (ls is num) {
      p.buffs.addBuff(
        NecromancerRingBuff(
          rarity: rarity,
          baseLifesteal: ls.toDouble(),
        ),
      );
    }

    final hpPct = params['maxHpPct'];
    if (hpPct is num) {
      _applyMaxHpPct(p, hpPct.toDouble());
    }

    game.notifyPlayerStatsChanged();
  }

  void _applyHunterMask(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;

    final crit = params['critChanceAdd'];
    if (crit is num) {
      p.stats.critChance = (p.stats.critChance + crit.toDouble()).clamp(0.0, 0.80);
    }

    final bossMult = params['bossDamageMult'];
    if (bossMult is num) {
      final next = game.runModifiers.bossDamageMultiplier * bossMult.toDouble();
      game.runModifiers.bossDamageMultiplier = next.clamp(0.2, 2.0);
    }

    game.notifyPlayerStatsChanged();
  }

  void _applyPanicBoots(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;

    final speedPct = params['moveSpeedPct'];
    if (speedPct is num) {
      p.stats.moveSpeed *= (1.0 + speedPct.toDouble());
    }

    final armorPct = params['armorPct'];
    if (armorPct is num) {
      final mult = (1.0 - armorPct.toDouble()).clamp(0.0, 1.0);
      p.stats.armor = max(0, (p.stats.armor * mult).round());
    }

    game.notifyPlayerStatsChanged();
  }

  void _applyMercuryAmulet(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;

    final atkPct = params['attackSpeedPct'];
    if (atkPct is num) {
      p.stats.attackSpeed *= (1.0 + atkPct.toDouble());
    }

    final manaPct = params['maxManaPct'];
    if (manaPct is num) {
      _applyMaxManaPct(p, manaPct.toDouble());
    }

    game.notifyPlayerStatsChanged();
  }

  void _applyPainMirror(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;

    final reflectPct = params['reflectPct'];
    if (reflectPct is num) {
      p.buffs.addBuff(
        PainMirrorBuff(
          rarity: rarity,
          baseReflectPct: reflectPct.toDouble(),
        ),
      );
    }

    final healMult = params['healMultiplier'];
    if (healMult is num) {
      final next = (p.stats.healMultiplier * healMult.toDouble()).clamp(0.1, 5.0);
      p.stats.healMultiplier = next;
    }

    game.notifyPlayerStatsChanged();
  }

  void _applyMaxHpDelta(PlayerComponent p, int delta) {
    p.stats.maxHp = max(1, p.stats.maxHp + delta);
    if (p.stats.hp > p.stats.maxHp) {
      p.stats.hp = p.stats.maxHp;
    }
  }

  void _applyMaxHpPct(PlayerComponent p, double pct) {
    if (pct <= 0) return;
    final mult = (1.0 - pct).clamp(0.1, 1.0);
    p.stats.maxHp = max(1, (p.stats.maxHp * mult).round());
    if (p.stats.hp > p.stats.maxHp) {
      p.stats.hp = p.stats.maxHp;
    }
  }

  void _applyMaxManaPct(PlayerComponent p, double pct) {
    if (pct <= 0) return;
    final mult = (1.0 - pct).clamp(0.0, 1.0);
    p.stats.maxMana = max(0.0, p.stats.maxMana * mult);
    if (p.stats.mana > p.stats.maxMana) {
      p.stats.mana = p.stats.maxMana;
    }
  }

  void _applyPhoenixHeart(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(PhoenixHeartBuff());
  }

  void _applyTimeCrystal(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(TimeCrystalBuff());
  }

  void _applyTitanShield(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(TitanShieldBuff());
  }

  void _applyStormHeart(
    PixelClashGame game,
    Map<String, Object?> params,
    PlayerBuildState build,
    Rarity rarity,
  ) {
    final p = game.player;
    if (p == null) return;
    p.buffs.addBuff(StormHeartBuff());
  }
}
