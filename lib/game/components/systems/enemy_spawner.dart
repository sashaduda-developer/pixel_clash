import 'dart:math';

import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/skeleton_enemy_factory.dart';
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

    // Чем больше mult — тем меньше кулдаун, тем чаще спавним.
    _cooldown = (baseCooldown / mult).clamp(0.12, 10.0).toDouble();

    _spawnEnemy();
  }

  void _spawnEnemy() {
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

    // Пока сила врагов зависит только от threat (как у тебя сейчас).
    var hp = 20 + t * 6;
    var dmg = 6 + t * 2;
    final speed = 95 + t * 6;

    // Очки уже зависят от "силы" (через threat multiplier).
    var scoreReward = (1 * threatSystem.scoreMultiplier).round().clamp(1, 999);

    // XP тоже зависит от threat (слегка).
    var xpReward = (2 + t * 0.5).round().clamp(1, 99);

    // Элитные враги: сильнее и дают больше награды.
    final isElite = _rng.nextDouble() < game.runModifiers.eliteChance;
    if (isElite) {
      hp = (hp * game.runModifiers.eliteHpMultiplier).round().clamp(1, 999999);
      dmg = (dmg * game.runModifiers.eliteDmgMultiplier).round().clamp(1, 999999);
      scoreReward = (scoreReward * game.runModifiers.eliteScoreMultiplier).round().clamp(1, 999999);
      xpReward = (xpReward * GameConstants.eliteBaseXpMultiplier).round().clamp(1, 999999);
      xpReward = (xpReward * game.runModifiers.eliteXpMultiplier).round().clamp(1, 999999);
    }

    xpReward = (xpReward * game.runModifiers.xpGainMultiplier).round().clamp(1, 999999);

    final factory = _pickFactory();
    final enemy = isElite
        ? factory.createElite(
            position: pos,
            speed: speed.toDouble(),
            hp: hp,
            damage: dmg,
            scoreReward: scoreReward,
            xpReward: xpReward,
          )
        : factory.createNormal(
            position: pos,
            speed: speed.toDouble(),
            hp: hp,
            damage: dmg,
            scoreReward: scoreReward,
            xpReward: xpReward,
          );

    world.add(enemy);
  }

  EnemyFactory _pickFactory() {
    if (_factories.isEmpty) {
      // Fallback, но список всегда должен быть заполнен.
      return SkeletonEnemyFactory();
    }
    return _factories[_rng.nextInt(_factories.length)];
  }
}
