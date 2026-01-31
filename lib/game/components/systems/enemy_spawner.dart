import 'dart:math';

import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_catalog.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/systems/threat_system.dart';
import 'package:pixel_clash/game/config/game_constants.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

class EnemySpawner extends Component with HasGameReference<PixelClashGame> {
  EnemySpawner({
    required this.threatSystem,
  });

  final ThreatSystem threatSystem;

  bool isPaused = false;

  final Random _rng = Random();
  double _cooldown = 0;
  double _cleanupTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isRewardPauseActive) return;
    if (isPaused) return;

    final p = game.player;
    if (p == null || p.isRemoving) return;

    _cooldown -= dt;
    _cleanupTimer -= dt;
    if (_cleanupTimer <= 0) {
      _cleanupTimer = 0.6;
      _cleanupEnemyOverflow();
      _despawnFarEnemies();
    }
    if (_cooldown > 0) return;

    // Base spawn cooldown (seconds).
    const base = 1.2;

    final progress = _runProgress();
    _syncThreatWithProgress(progress);

    // Threat reduces cooldown as it rises.
    final t = threatSystem.level;
    final baseCooldown = (base - t * 0.04).clamp(0.70, 10.0).toDouble();

    // ===== Book of Hardship =====
    // This book only affects this run: increases enemy spawn rate.
    // It does NOT change enemy power or the map.
    //
    // Example:
    // - multiplier = 1.0 => no book
    // - multiplier = 1.25 => +25% enemies (spawn more often)
    final mult = game.runModifiers.enemySpawnRateMultiplier;
    final progressCurve = pow(progress, 1.15).toDouble();
    final spawnEase = (0.80 + progress * 0.35).clamp(0.80, 1.0);
    final timeMult = (1.0 + progressCurve * 0.45) * spawnEase;

    // Higher multiplier => shorter cooldown => more spawns.
    _cooldown = (baseCooldown / (mult * timeMult)).clamp(0.22, 10.0).toDouble();

    if (_activeEnemyCount() >= _maxEnemyCount(progress)) {
      _cooldown = max(_cooldown, 0.6);
      return;
    }

    _spawnEnemy();
  }

  void spawnSwarm({
    required int count,
    double eliteChanceBonus = 0.0,
  }) {
    final base = game.runModifiers.eliteChance;
    final override = (base + eliteChanceBonus).clamp(0.0, 0.8);

    for (var i = 0; i < count; i++) {
      _spawnEnemy(eliteChanceOverride: override);
    }
  }

  void _syncThreatWithProgress(double progress) {
    final target = (pow(progress, 1.05) * 3).floor();
    while (threatSystem.level < target) {
      threatSystem.increaseThreat();
    }
  }

  double _runProgress() {
    const total = GameConstants.biomeDurationSeconds;
    if (total <= 0) return 0.0;
    final left = game.timeLeft.value;
    return (1.0 - (left / total)).clamp(0.0, 1.0);
  }

  int _maxEnemyCount(double progress) {
    const base = 26;
    final scaled = base + (progress * 14).round() + game.mapIndex * 3;
    return scaled.clamp(26, 55);
  }

  int _activeEnemyCount() {
    var count = 0;
    for (final c in game.worldMap.children) {
      if (c is! EnemyComponent) continue;
      if (c.isDead || c.isRemoving) continue;
      if (c.isBoss) continue;
      count += 1;
    }
    return count;
  }

  void _cleanupEnemyOverflow() {
    final player = game.player;
    if (player == null) return;
    final progress = _runProgress();
    final maxEnemies = _maxEnemyCount(progress);

    final enemies = <EnemyComponent>[];
    for (final c in game.worldMap.children) {
      if (c is! EnemyComponent) continue;
      if (c.isDead || c.isRemoving) continue;
      if (c.isBoss) continue;
      enemies.add(c);
    }

    if (enemies.length <= maxEnemies) return;

    enemies.sort((a, b) {
      final da = a.position.distanceToSquared(player.position);
      final db = b.position.distanceToSquared(player.position);
      return db.compareTo(da);
    });

    var over = enemies.length - maxEnemies;
    for (final e in enemies) {
      if (over <= 0) break;
      if (!e.isRemoving) {
        e.removeFromParent();
        over -= 1;
      }
    }
  }

  void _despawnFarEnemies() {
    final player = game.player;
    if (player == null) return;
    const maxDist = 1000.0;
    const maxDist2 = maxDist * maxDist;

    final toRemove = <EnemyComponent>[];
    for (final c in game.worldMap.children) {
      if (c is! EnemyComponent) continue;
      if (c.isDead || c.isRemoving) continue;
      if (c.isBoss) continue;
      if (c.position.distanceToSquared(player.position) > maxDist2) {
        toRemove.add(c);
      }
    }
    for (final c in toRemove) {
      if (!c.isRemoving) c.removeFromParent();
    }
  }

  void _spawnEnemy({double? eliteChanceOverride}) {
    final player = game.player!;
    final world = game.worldMap;

    final angle = _rng.nextDouble() * pi * 2;
    final dist = GameConstants.enemySpawnMinDist +
        _rng.nextDouble() * (GameConstants.enemySpawnMaxDist - GameConstants.enemySpawnMinDist);

    final rawPos = Vector2(
      player.position.x + cos(angle) * dist,
      player.position.y + sin(angle) * dist,
    );

    final pos = world.clampToMap(rawPos);

    final t = threatSystem.level;
    final progress = _runProgress();
    final progressCurve = pow(progress, 1.15).toDouble();
    final level = game.xpSystem.level;
    final mapScale = 1.0 + game.mapIndex * 0.06;

    // Scale enemy power with progress + player level.
    var hp = (15 + t * 3.5).toDouble();
    var dmg = (4 + t * 1.0).toDouble();
    var speed = (78 + t * 2.5).toDouble();

    final hpScale =
        (1.0 + progressCurve * 0.30) * (1.0 + max(0, level - 1) * 0.012) * mapScale;
    final dmgScale = (1.0 + progressCurve * 0.24) *
        (1.0 + max(0, level - 1) * 0.009) *
        (1.0 + game.mapIndex * 0.04);
    final speedScale = 1.0 + progressCurve * 0.05 + game.mapIndex * 0.015;

    hp *= hpScale;
    dmg *= dmgScale;
    speed *= speedScale;

    final statEase = (0.75 + progress * 0.35).clamp(0.75, 1.0);
    hp *= statEase;
    dmg *= statEase;
    speed *= statEase;

    // Очки уже зависят от "силы" (через threat multiplier).
    var scoreReward = (1 * threatSystem.scoreMultiplier).round().clamp(1, 999);

    // XP тоже зависит от threat (слегка).
    var xpReward = (2 + t * 0.16).round().clamp(1, 99);

    // Элитные враги: сильнее и дают больше награды.
    final baseChance = game.runModifiers.eliteChance;
    const eliteStartProgress = 0.18;
    final eliteProgress =
        ((progress - eliteStartProgress) / (1.0 - eliteStartProgress)).clamp(0.0, 1.0);
    final timeBonus = (eliteProgress * 0.10).clamp(0.0, 0.3);
    final chance =
        eliteChanceOverride ?? ((baseChance + timeBonus) * eliteProgress).clamp(0.0, 0.8);
    final isElite = eliteProgress > 0 && _rng.nextDouble() < chance;
    if (isElite) {
      const baseEliteHpMult = 1.6;
      const baseEliteDmgMult = 1.3;
      hp = (hp * baseEliteHpMult * game.runModifiers.eliteHpMultiplier).clamp(1.0, 999999.0);
      dmg = (dmg * baseEliteDmgMult * game.runModifiers.eliteDmgMultiplier).clamp(1.0, 999999.0);
      scoreReward = (scoreReward * game.runModifiers.eliteScoreMultiplier).round().clamp(1, 999999);
      xpReward = (xpReward * GameConstants.eliteBaseXpMultiplier).round().clamp(1, 999999);
      xpReward = (xpReward * game.runModifiers.eliteXpMultiplier).round().clamp(1, 999999);
    }

    xpReward = (xpReward * game.runModifiers.xpGainMultiplier).round().clamp(1, 999999);

    final factory = EnemyCatalog.pickFactory(
      mapIndex: game.mapIndex,
      progress: progress,
      rng: _rng,
    );
    final enemy = isElite
        ? factory.createElite(
            position: pos,
            speed: speed.toDouble(),
            hp: hp.round(),
            damage: dmg.round(),
            scoreReward: scoreReward,
            xpReward: xpReward,
          )
        : factory.createNormal(
            position: pos,
            speed: speed.toDouble(),
            hp: hp.round(),
            damage: dmg.round(),
            scoreReward: scoreReward,
            xpReward: xpReward,
          );

    world.add(enemy);
  }
}
