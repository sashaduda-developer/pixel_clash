import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/active_ability.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/interactables/altar_component.dart';
import 'package:pixel_clash/game/components/interactables/chest_component.dart';
import 'package:pixel_clash/game/components/player/hero_type.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/components/systems/biome_timer.dart';
import 'package:pixel_clash/game/components/systems/enemy_spawner.dart';
import 'package:pixel_clash/game/components/systems/score_system.dart';
import 'package:pixel_clash/game/components/systems/threat_system.dart';
import 'package:pixel_clash/game/components/systems/xp_system.dart';
import 'package:pixel_clash/game/components/world/world_map.dart';
import 'package:pixel_clash/game/config/game_constants.dart';
import 'package:pixel_clash/game/data/app_database.dart';
import 'package:pixel_clash/game/data/reward_repository.dart';
import 'package:pixel_clash/game/data/reward_seeder.dart';
import 'package:pixel_clash/game/localization/app_locale.dart';
import 'package:pixel_clash/game/localization/l10n.dart';
import 'package:pixel_clash/game/rewards/icon_registry.dart';
import 'package:pixel_clash/game/rewards/player_build_state.dart';
import 'package:pixel_clash/game/rewards/reward_definition.dart';
import 'package:pixel_clash/game/rewards/upgrade_registry.dart';
import 'package:pixel_clash/game/run/run_modifiers.dart';
import 'package:pixel_clash/game/ui/overlays.dart';

class PixelClashGame extends FlameGame with HasCollisionDetection {
  PixelClashGame();

  final int seed = DateTime.now().millisecondsSinceEpoch;
  late final Random rng = Random(seed);
  int mapIndex = 0;

  late final WorldMap worldMap;
  late final CameraComponent cam;

  PlayerComponent? player;

  late final BiomeTimer biomeTimer;
  late final ThreatSystem threatSystem;
  late final ScoreSystem scoreSystem;
  late final EnemySpawner enemySpawner;

  late final XpSystem xpSystem;

  late final JoystickComponent joystick;

  // Локализация
  final L10n l10n = L10n(initial: AppLocale.ru);

  // HUD ValueNotifiers
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> threatLevel = ValueNotifier<int>(0);
  final ValueNotifier<double> timeLeft = ValueNotifier<double>(0);
  final ValueNotifier<int> keysFound = ValueNotifier<int>(0);

  // HP игрока
  final ValueNotifier<int> playerHp = ValueNotifier<int>(0);
  final ValueNotifier<int> playerMaxHp = ValueNotifier<int>(1);
  final ValueNotifier<int> playerArmor = ValueNotifier<int>(0);
  final ValueNotifier<double> playerMana = ValueNotifier<double>(0);
  final ValueNotifier<double> playerMaxMana = ValueNotifier<double>(1);

  /// Слоты активных способностей (id или null).
  final ValueNotifier<List<String?>> abilitySlots =
      ValueNotifier<List<String?>>(List<String?>.filled(4, null));

  final ValueNotifier<int> level = ValueNotifier<int>(1);
  final ValueNotifier<double> xpProgress = ValueNotifier<double>(0);

  final ValueNotifier<List<RewardDefinition>> rewardChoices =
      ValueNotifier<List<RewardDefinition>>(<RewardDefinition>[]);

  // ===== Build/Upgrades =====
  late final AppDatabase db;
  late final UpgradeRegistry upgradeRegistry;
  late final PlayerBuildState buildState;
  late final RewardRepository rewardRepository;
  final RunModifiers runModifiers = RunModifiers();

  // ===== HIT-STOP =====
  bool _hitStopInProgress = false;
  double _hitStopCooldown = 0;

  /// Лок паузы: когда открыт выбор награды, никто не имеет права снимать паузу.
  bool _rewardPauseLock = false;

  // ===== CAMERA SHAKE (только на крит) =====
  double _shakeLeft = 0;
  double _shakeStrength = 0;

  @override
  Color backgroundColor() => const Color(0xFF1A1A1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // DB + repository
    db = AppDatabase();
    upgradeRegistry = UpgradeRegistry();
    buildState = PlayerBuildState();
    rewardRepository = RewardRepository(
      db: db,
      registry: upgradeRegistry,
      icons: const IconRegistry(),
    );

    await RewardSeeder.ensureSeeded(db);

    worldMap = WorldMap();
    add(worldMap);

    cam = CameraComponent.withFixedResolution(
      world: worldMap,
      width: GameConstants.cameraWidth,
      height: GameConstants.cameraHeight,
    );
    add(cam);

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 18,
        paint: Paint()..color = const Color(0xAAFFFFFF),
      ),
      background: CircleComponent(
        radius: 42,
        paint: Paint()..color = const Color(0x33FFFFFF),
      ),
      margin: const EdgeInsets.only(left: 28, bottom: 28),
    );
    cam.viewport.add(joystick);

    scoreSystem = ScoreSystem(onScoreChanged: (v) => score.value = v);
    threatSystem = ThreatSystem(onThreatChanged: (v) => threatLevel.value = v);

    biomeTimer = BiomeTimer(
      durationSeconds: GameConstants.biomeDurationSeconds,
      onTimeChanged: (t) => timeLeft.value = t,
      onTimeIsOver: _onBiomeTimeOver,
    );

    xpSystem = XpSystem(
      onXpChanged: (cur, toNext) {
        xpProgress.value = toNext == 0 ? 0 : (cur / toNext).clamp(0.0, 1.0);
      },
      onLevelChanged: (lv) => level.value = lv,
      onLevelUp: (_) {
        unawaited(_pauseAndShowRewards(RewardSource.levelUp));
      },
    );

    enemySpawner = EnemySpawner(
      threatSystem: threatSystem,
      scoreSystem: scoreSystem,
    );

    add(scoreSystem);
    add(threatSystem);
    add(biomeTimer);
    add(xpSystem);
    add(enemySpawner);

    overlays.add(Overlays.heroSelect);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _hitStopCooldown = max(0, _hitStopCooldown - dt);

    if (_shakeLeft > 0) {
      _shakeLeft -= dt;
      final dx = (rng.nextDouble() * 2 - 1) * _shakeStrength;
      final dy = (rng.nextDouble() * 2 - 1) * _shakeStrength;
      cam.viewfinder.position.add(Vector2(dx, dy));
    }
  }

  // ===== public helpers =====

  void requestHitStop(double duration) {
    // Если открыт выбор награды — никакого hit-stop и главное:
    // нельзя ставить на паузу/снимать паузу таймером, иначе сломаем reward overlay.
    if (_rewardPauseLock) return;

    if (_hitStopInProgress) return;
    if (_hitStopCooldown > 0) return;

    _hitStopInProgress = true;
    _hitStopCooldown = 0.08;

    pauseEngine();
    Future<void>.delayed(
      Duration(milliseconds: (duration * 1000).round()),
      () {
        _hitStopInProgress = false;

        // ВАЖНО: если за время hit-stop открылся reward overlay,
        // мы НЕ должны резюмить движок.
        if (_rewardPauseLock) return;

        resumeEngine();
      },
    );
  }

  void requestCritShake() {
    _shakeLeft = 0.10;
    _shakeStrength = 1.8;
  }

  // ===== start/reset =====

  Future<void> startGame(HeroType heroType) async {
    overlays.remove(Overlays.heroSelect);

    // билд сбрасываем на новый ран
    buildState.stacks.clear();
    runModifiers.reset();
    abilitySlots.value = List<String?>.filled(4, null);

    scoreSystem.reset();
    threatSystem.reset();
    xpSystem.reset();

    player?.removeFromParent();
    player = null;

    final spawn = worldMap.mapSize / 2;

    final newPlayer = PlayerComponent(
      heroType: heroType,
      position: spawn,
    );

    player = newPlayer;
    await worldMap.add(newPlayer);

    _syncPlayerStatsToHud();

    cam.follow(newPlayer);

    spawnStaticInteractablesForCurrentMap();

    biomeTimer.resetAndStart();
    enemySpawner.isPaused = false;

    overlays.remove(Overlays.rewardPick);
    rewardChoices.value = <RewardDefinition>[];

    _hitStopInProgress = false;
    _hitStopCooldown = 0;

    resumeEngine();
  }

  int mapSeedForIndex(int index) {
    return seed ^ (index * 1000003);
  }

  void spawnStaticInteractablesForCurrentMap() {
    worldMap.children.whereType<ChestComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<AltarComponent>().forEach((c) => c.removeFromParent());

    final mapRng = Random(mapSeedForIndex(mapIndex));

    const chestCount = 12;
    for (var i = 0; i < chestCount; i++) {
      final pos = _randomPointOnMap(mapRng);
      worldMap.add(
        ChestComponent(
          position: pos,
          openTime: 2.0,
          interactRadius: 54,
        ),
      );
    }

    const altarCount = 4;
    for (var i = 0; i < altarCount; i++) {
      final pos = _randomPointOnMap(mapRng);
      worldMap.add(
        AltarComponent(
          position: pos,
          openTime: 2.2,
          interactRadius: 58,
        ),
      );
    }
  }

  Vector2 _randomPointOnMap(Random r) {
    const margin = 80.0;
    final w = worldMap.mapSize.x;
    final h = worldMap.mapSize.y;

    final x = margin + r.nextDouble() * max(1.0, w - margin * 2);
    final y = margin + r.nextDouble() * max(1.0, h - margin * 2);

    return Vector2(x, y);
  }

  // ===== rewards entrypoints =====

  Future<void> onChestOpened() async {
    await _pauseAndShowRewards(RewardSource.chest);
  }

  Future<void> onAltarActivated() async {
    await _pauseAndShowRewards(RewardSource.altar);
  }

  /// Унифицированная точка показа наград.
  /// Важно:
  /// - сначала ставим игру на паузу
  /// - потом роллим награды
  /// - если наград нет => паузу снимаем и ничего не показываем
  Future<void> _pauseAndShowRewards(RewardSource source) async {
    // Лочим паузу наград — пока не выберут карточку, не резюмим движок.
    _rewardPauseLock = true;

    // Останавливаем движок.
    pauseEngine();

    // Роллим награды.
    final rolled = await rewardRepository.roll(
      source: source,
      count: 3,
      rng: rng,
      l10n: l10n,
      game: this,
      build: buildState,
    );

    // Если наград нет — снимаем лок и продолжаем игру.
    if (rolled.isEmpty) {
      _rewardPauseLock = false;
      resumeEngine();
      return;
    }

    rewardChoices.value = rolled;
    if (!overlays.isActive(Overlays.rewardPick)) {
      overlays.add(Overlays.rewardPick);
    }
  }

  /// Вызывается UI после выбора карточки.
  void applyRewardAndResume(RewardDefinition reward) {
    reward.apply(this);

    overlays.remove(Overlays.rewardPick);
    rewardChoices.value = <RewardDefinition>[];

    // Снимаем лок и продолжаем игру.
    _rewardPauseLock = false;
    resumeEngine();
  }

  // ===== HUD sync / lifecycle =====

  void _syncPlayerStatsToHud() {
    final p = player;
    if (p == null) {
      playerHp.value = 0;
      playerMaxHp.value = 1;
      playerArmor.value = 0;
      playerMana.value = 0;
      playerMaxMana.value = 1;

      return;
    }

    playerHp.value = p.hp;
    playerMaxHp.value = p.maxHp;
    playerArmor.value = p.stats.armor;
    playerMana.value = p.stats.mana;
    playerMaxMana.value = p.stats.maxMana;
  }

  /// Регистрирует активную способность в слоте (первый свободный).
  /// Если уже есть — не меняем.
  void assignAbilitySlot(String abilityId) {
    final list = List<String?>.from(abilitySlots.value);
    if (list.contains(abilityId)) return;

    final idx = list.indexOf(null);
    if (idx == -1) return;

    list[idx] = abilityId;
    abilitySlots.value = list;
  }

  /// Пытается активировать способность из слота.
  bool tryActivateAbilitySlot(int slotIndex) {
    final p = player;
    if (p == null) return false;

    final slots = abilitySlots.value;
    if (slotIndex < 0 || slotIndex >= slots.length) return false;

    final id = slots[slotIndex];
    if (id == null) return false;

    final ability = p.buffs.getBuffAs<ActiveAbility>(id);
    if (ability == null) return false;

    final ok = ability.tryActivate(p);
    if (ok) notifyPlayerStatsChanged();
    return ok;
  }

  void notifyPlayerStatsChanged() => _syncPlayerStatsToHud();

  void onPlayerDied() {
    enemySpawner.isPaused = true;

    joystick.delta.setZero();
    joystick.relativeDelta.setZero();

    _syncPlayerStatsToHud();

    overlays.add(Overlays.heroSelect);
  }

  void _onBiomeTimeOver() {
    enemySpawner.isPaused = true;
    overlays.add(Overlays.heroSelect);
  }

  EnemyComponent? findNearestEnemyInRadius(
    Vector2 center,
    double radius, {
    Set<EnemyComponent>? exclude,
  }) {
    final r2 = radius * radius;

    EnemyComponent? best;
    double bestD2 = double.infinity;

    for (final c in worldMap.children) {
      if (c is! EnemyComponent) continue;
      if (c.isDead || c.isRemoving) continue;
      if (exclude != null && exclude.contains(c)) continue;

      final d2 = c.position.distanceToSquared(center);
      if (d2 > r2) continue;

      if (d2 < bestD2) {
        bestD2 = d2;
        best = c;
      }
    }

    return best;
  }

  // ===== locale dev =====
  void setLocaleRu() => l10n.setLocale(AppLocale.ru);
  void setLocaleEn() => l10n.setLocale(AppLocale.en);

  @override
  void onRemove() {
    // Закрываем DB при выгрузке игры.
    unawaited(db.close());
    super.onRemove();
  }
}
