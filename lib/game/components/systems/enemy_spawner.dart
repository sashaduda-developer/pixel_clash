import 'dart:math';

import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/skeleton_enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/wraith_enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/brute_enemy_factory.dart';
import 'package:pixel_clash/game/components/systems/score_system.dart';
import 'package:pixel_clash/game/components/systems/threat_system.dart';
import 'package:pixel_clash/game/config/game_constants.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

class EnemySpawner extends Component with HasGameReference<PixelClashGame> {
  EnemySpawner({
    required this.threatSystem,
    required this.scoreSystem,
  });

  final ThreatSystem threatSystem;
  final ScoreSystem scoreSystem;

  bool isPaused = false;

  final Random _rng = Random();
  double _cooldown = 0;
  final List<EnemyFactory> _factories = <EnemyFactory>[
    SkeletonEnemyFactory(),
    WraithEnemyFactory(),
    BruteEnemyFactory(),
  ];

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isRewardPauseActive) return;
    if (isPaused) return;

    final p = game.player;
    if (p == null || p.isRemoving) return;

    _cooldown -= dt;
    if (_cooldown > 0) return;

    // Базовый кулдаун спавна (сек).
    const base = 1.2;

    // Threat ускоряет спавн (чем выше threat — тем чаще).
    final t = threatSystem.level;
    final baseCooldown = (base - t * 0.10).clamp(0.25, 10.0).toDouble();

    // ===== КНИГА ИСПЫТАНИЙ =====
    // Книга усложняет ТОЛЬКО твой ран: увеличивает частоту спавна врагов.
    // Это НЕ меняет силу врагов и НЕ меняет карту.
    //
    // Пример:
    // - multiplier = 1.0 => без книги
    // - multiplier = 1.25 => +25% врагов (спавн чаще)
    final mult = game.runModifiers.enemySpawnRateMultiplier;
    final progress = _runProgress();
    final timeMult = (1.0 + progress * 0.8);

    // Чем больше mult — тем меньше кулдаун, тем чаще спавним.
    _cooldown = (baseCooldown / (mult * timeMult)).clamp(0.12, 10.0).toDouble();

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

  double _runProgress() {
    const total = GameConstants.biomeDurationSeconds;
    if (total <= 0) return 0.0;
    final left = game.timeLeft.value;
    return (1.0 - (left / total)).clamp(0.0, 1.0);
  }

  EnemyFactory _pickFactoryForProgress(double progress) {
    final wraithWeight = ((progress - 0.10) / 0.90).clamp(0.0, 1.0) * 0.90;
    final bruteWeight = ((progress - 0.45) / 0.55).clamp(0.0, 1.0) * 0.70;

    final pool = <_WeightedFactory>[
      const _WeightedFactory(factoryId: 'skeleton', weight: 1.0),
      if (wraithWeight > 0) _WeightedFactory(factoryId: 'wraith', weight: wraithWeight),
      if (bruteWeight > 0) _WeightedFactory(factoryId: 'brute', weight: bruteWeight),
    ];
    final total = pool.fold(0.0, (sum, e) => sum + e.weight);
    var roll = _rng.nextDouble() * total;
    for (final e in pool) {
      roll -= e.weight;
      if (roll <= 0) {
        return _factoryById(e.factoryId);
      }
    }
    return _factoryById(pool.last.factoryId);
  }

  EnemyFactory _factoryById(String id) {
    for (final f in _factories) {
      if (f.id == id) return f;
    }
    return _factories.first;
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

    // Пока сила врагов зависит только от threat (как у тебя сейчас).
    var hp = (20 + t * 6).toDouble();
    var dmg = (6 + t * 2).toDouble();
    final speed = 95 + t * 6;

    // Очки уже зависят от "силы" (через threat multiplier).
    var scoreReward = (1 * threatSystem.scoreMultiplier).round().clamp(1, 999);

    // XP тоже зависит от threat (слегка).
    var xpReward = (2 + t * 0.5).round().clamp(1, 99);

    // Элитные враги: сильнее и дают больше награды.
    final baseChance = game.runModifiers.eliteChance;
    final timeBonus = (progress * 0.10).clamp(0.0, 0.3);
    final chance = eliteChanceOverride ?? (baseChance + timeBonus).clamp(0.0, 0.8);
    final isElite = _rng.nextDouble() < chance;
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

    final factory = _pickFactoryForProgress(progress);
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

class _WeightedFactory {
  const _WeightedFactory({required this.factoryId, required this.weight});
  final String factoryId;
  final double weight;
}
