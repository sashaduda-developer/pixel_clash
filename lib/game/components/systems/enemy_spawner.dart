import 'dart:math';

import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/config/game_constants.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/components/systems/score_system.dart';
import 'package:pixel_clash/game/components/systems/threat_system.dart';

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

  @override
  void update(double dt) {
    super.update(dt);

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
    final hp = 20 + t * 6;
    final dmg = 6 + t * 2;
    final speed = 95 + t * 6;

    // Очки уже зависят от "силы" (через threat multiplier).
    final scoreReward = (1 * threatSystem.scoreMultiplier).round().clamp(1, 999);

    // XP тоже зависит от threat (слегка).
    final xpReward = (2 + t * 0.5).round().clamp(1, 99);

    world.add(
      EnemyComponent(
        position: pos,
        speed: speed.toDouble(),
        hp: hp,
        damage: dmg,
        scoreReward: scoreReward,
        xpReward: xpReward,
      ),
    );
  }
}
