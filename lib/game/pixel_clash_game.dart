import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/camera.dart' show FixedResolutionViewport;
import 'package:flame/components.dart' hide Timer;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/active_ability.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/enemies/types/final_boss.dart';
import 'package:pixel_clash/game/components/enemies/types/lancer_boss.dart';
import 'package:pixel_clash/game/components/enemies/types/skeleton_boss.dart';
import 'package:pixel_clash/game/components/interactables/altar_component.dart';
import 'package:pixel_clash/game/components/interactables/chest_component.dart';
import 'package:pixel_clash/game/components/interactables/key_component.dart';
import 'package:pixel_clash/game/components/interactables/portal_component.dart';
import 'package:pixel_clash/game/components/interactables/potion_component.dart';
import 'package:pixel_clash/game/components/player/hero_definition.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';
import 'package:pixel_clash/game/components/systems/biome_timer.dart';
import 'package:pixel_clash/game/components/systems/enemy_spawner.dart';
import 'package:pixel_clash/game/components/systems/score_system.dart';
import 'package:pixel_clash/game/components/systems/threat_system.dart';
import 'package:pixel_clash/game/components/systems/xp_system.dart';
import 'package:pixel_clash/game/components/world/world_map.dart';
import 'package:pixel_clash/game/components/xp/xp_crystal_component.dart';
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

  static const int requiredKeys = 3;

  final int seed = DateTime.now().millisecondsSinceEpoch;
  late final Random rng = Random(seed);

  int mapIndex = 0;

  late final WorldMap worldMap;

  late final CameraComponent cam;
  bool _cameraReady = false;

  PlayerComponent? player;
  PortalComponent? _portal;

  late final BiomeTimer biomeTimer;
  late final ThreatSystem threatSystem;

  late final ScoreSystem scoreSystem;
  late final EnemySpawner enemySpawner;

  late final XpSystem xpSystem;

  late final JoystickComponent joystick;

  // Локализация
  final L10n l10n = L10n(initial: AppLocale.ru);

  // Значения HUD (ValueNotifier)
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

  // HUD босса
  final ValueNotifier<int> bossHp = ValueNotifier<int>(0);
  final ValueNotifier<int> bossMaxHp = ValueNotifier<int>(0);
  final ValueNotifier<String> bossName = ValueNotifier<String>('');
  final ValueNotifier<String> announcementText = ValueNotifier<String>('');

  final ValueNotifier<List<String?>> abilitySlots =
      ValueNotifier<List<String?>>(List<String?>.filled(4, null));

  final ValueNotifier<int> level = ValueNotifier<int>(1);
  final ValueNotifier<double> xpProgress = ValueNotifier<double>(0);

  final ValueNotifier<List<RewardDefinition>> rewardChoices =
      ValueNotifier<List<RewardDefinition>>(<RewardDefinition>[]);
  final ValueNotifier<RewardDefinition?> bossRewardChoice = ValueNotifier<RewardDefinition?>(null);
  final List<RewardSource> _rewardQueue = <RewardSource>[];
  bool _rewardOverlayOpen = false;

  // ===== Прогресс и апгрейды =====
  late final AppDatabase db;
  late final UpgradeRegistry upgradeRegistry;
  late final PlayerBuildState buildState;
  late final RewardRepository rewardRepository;
  final RunModifiers runModifiers = RunModifiers();

  // ===== Hit-stop =====
  bool _hitStopInProgress = false;
  double _hitStopCooldown = 0;
  bool _firstBossSpawned = false;
  bool _firstBossWarned = false;

  bool _firstBossKeyDropped = false;
  bool _finalBossSpawned = false;
  bool _finalBossDefeated = false;
  bool _portalTransitionInProgress = false;
  bool _swarmSpawned = false;
  bool _swarmWarned = false;
  Timer? _announcementTimer;

  bool _rewardPauseLock = false;
  final Set<String> _chestSeenRewardIds = <String>{};
  int _chestCommonStreak = 0;
  int _altarNoAbilityStreak = 0;
  int _legendaryNoHitStreak = 0;
  final Set<String> _bossSeenRewardIds = <String>{};

  // ===== CAMERA SHAKE (только на крит) =====
  double _shakeLeft = 0;
  final double _shakeStrength = 0;

  @override

  /// Описание метода backgroundColor.
  Color backgroundColor() => const Color(0xFF1A1A1A);

  @override

  /// Описание метода onLoad.
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
    _cameraReady = true;
    _applyPixelPerfectCamera();

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
      onTimeChanged: _onBiomeTimeChanged,
      onTimeIsOver: _onBiomeTimeOver,
    );

    xpSystem = XpSystem(
      onXpChanged: (cur, toNext) {
        xpProgress.value = toNext == 0 ? 0 : (cur / toNext).clamp(0.0, 1.0);
      },
      onLevelChanged: (lv) => level.value = lv,
      onLevelUp: (_) {
        _enqueueRewardOverlay(RewardSource.levelUp);
      },
    );

    enemySpawner = EnemySpawner(
      threatSystem: threatSystem,
    );

    add(scoreSystem);
    add(threatSystem);
    add(biomeTimer);
    add(xpSystem);
    add(enemySpawner);
    add(
      FpsTextComponent(
        position: Vector2(10, 10),
        anchor: Anchor.topLeft,
      ),
    );
    if (!overlays.isActive(Overlays.startMenu)) {
      overlays.add(Overlays.startMenu);
    }
  }

  @override

  /// Описание метода update.
  void update(double dt) {
    super.update(dt);

    _hitStopCooldown = max(0, _hitStopCooldown - dt);

    if (_shakeLeft > 0 && _cameraReady) {
      _shakeLeft -= dt;
      final dx = (rng.nextDouble() * 2 - 1) * _shakeStrength;
      final dy = (rng.nextDouble() * 2 - 1) * _shakeStrength;
      cam.viewfinder.position.add(Vector2(dx, dy));
    }
    _applyPixelPerfectCamera();
  }

  /// Описание метода _applyPixelPerfectCamera.
  void _applyPixelPerfectCamera() {
    if (!_cameraReady) return;
    _snapCameraZoomToTileGrid();
    _snapCameraPosition();
  }

  /// Описание метода _snapCameraZoomToTileGrid.
  void _snapCameraZoomToTileGrid() {
    final viewportScale = _viewportScale();
    if (viewportScale <= 0) return;

    final tileSize = WorldMap.tileSize.x;
    if (tileSize <= 0) return;

    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final scale = viewportScale * cam.viewfinder.zoom;
    final tilePx = tileSize * scale * dpr;
    if (tilePx <= 0) return;

    final snappedTilePx = tilePx.roundToDouble().clamp(1.0, double.infinity);
    final snappedScale = snappedTilePx / (tileSize * dpr);
    final snappedZoom = snappedScale / viewportScale;

    if ((snappedZoom - cam.viewfinder.zoom).abs() > 0.0001) {
      cam.viewfinder.zoom = snappedZoom;
    }
  }

  /// Описание метода _snapCameraPosition.
  void _snapCameraPosition() {
    final viewportScale = _viewportScale();
    if (viewportScale <= 0) return;

    final scale = viewportScale * cam.viewfinder.zoom;
    if (scale <= 0) return;

    final anchor = cam.viewfinder.anchor;
    final anchorPos = Vector2(
      cam.viewport.virtualSize.x * anchor.x,
      cam.viewport.virtualSize.y * anchor.y,
    );

    final viewport = cam.viewport;
    final viewportOffset = Vector2(
      viewport.position.x - viewport.anchor.x * viewport.size.x,
      viewport.position.y - viewport.anchor.y * viewport.size.y,
    );

    final offset = viewportOffset + anchorPos * viewportScale;
    final pos = cam.viewfinder.position;
    final translationX = offset.x - pos.x * scale;
    final translationY = offset.y - pos.y * scale;

    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final snappedTranslationX = (translationX * dpr).roundToDouble() / dpr;
    final snappedTranslationY = (translationY * dpr).roundToDouble() / dpr;

    final snappedX = (offset.x - snappedTranslationX) / scale;
    final snappedY = (offset.y - snappedTranslationY) / scale;

    if ((snappedX - pos.x).abs() > 0.0001 || (snappedY - pos.y).abs() > 0.0001) {
      cam.viewfinder.position = Vector2(snappedX, snappedY);
    }
  }

  /// Описание метода _viewportScale.
  double _viewportScale() {
    final viewport = cam.viewport;
    if (viewport is FixedResolutionViewport) {
      return viewport.scale.x;
    }
    return 1.0;
  }

  // ===== public helpers =====

  /// Геттер isRewardPauseActive.
  bool get isRewardPauseActive => _rewardPauseLock;

  /// Описание метода requestHitStop.
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

  // ===== start/reset =====

  /// Описание метода startGame.
  Future<void> startGame(HeroDefinition hero) async {
    overlays.remove(Overlays.heroSelect);

    // билд сбрасываем на новый ран
    buildState.stacks.clear();
    _chestSeenRewardIds.clear();
    _chestCommonStreak = 0;
    _altarNoAbilityStreak = 0;
    _legendaryNoHitStreak = 0;
    _bossSeenRewardIds.clear();
    runModifiers.reset();
    abilitySlots.value = List<String?>.filled(4, null);
    mapIndex = 0;
    keysFound.value = 0;
    _firstBossSpawned = false;
    _firstBossWarned = false;
    _firstBossKeyDropped = false;
    _finalBossSpawned = false;
    _finalBossDefeated = false;
    _portalTransitionInProgress = false;
    _portal = null;
    _swarmSpawned = false;
    _swarmWarned = false;
    clearBossHud();
    _announcementTimer?.cancel();
    _announcementTimer = null;
    announcementText.value = '';

    scoreSystem.reset();
    threatSystem.reset();
    xpSystem.reset();

    worldMap.children.whereType<EnemyComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<XpCrystalComponent>().forEach((c) => c.removeFromParent());
    player?.removeFromParent();
    player = null;

    final spawn = worldMap.mapSize / 2;

    final newPlayer = PlayerComponent(
      hero: hero,
      position: spawn,
    );

    player = newPlayer;
    await worldMap.add(newPlayer);

    _syncPlayerStatsToHud();

    cam.follow(newPlayer, snap: true);

    spawnStaticInteractablesForCurrentMap();

    biomeTimer.resetAndStart();
    enemySpawner.isPaused = false;

    overlays.remove(Overlays.rewardPick);
    rewardChoices.value = <RewardDefinition>[];
    overlays.remove(Overlays.bossReward);
    bossRewardChoice.value = null;
    _rewardQueue.clear();
    _rewardOverlayOpen = false;
    _rewardPauseLock = false;

    _hitStopInProgress = false;
    _hitStopCooldown = 0;

    resumeEngine();
  }

  /// Описание метода _spawnFirstBoss.
  void _spawnFirstBoss() {
    worldMap.children.whereType<SkeletonBossComponent>().forEach((b) => b.removeFromParent());
    worldMap.children
        .whereType<ArmoredSkeletonBossComponent>()
        .forEach((b) => b.removeFromParent());
    worldMap.children
        .whereType<GreatswordSkeletonBossComponent>()
        .forEach((b) => b.removeFromParent());

    final p = player;
    if (p == null) return;

    final pos = worldMap.clampToMap(p.position + Vector2(220, 0));
    final (hpScale, dmgScale, speedScale) = _bossScales();

    final roll = rng.nextInt(3);
    final boss = switch (roll) {
      0 => SkeletonBossComponent(
          position: pos,
          speed: 70 * speedScale,
          hp: max(1, (320 * hpScale).round()),
          damage: max(1, (16 * dmgScale).round()),
        ),
      1 => ArmoredSkeletonBossComponent(
          position: pos,
          speed: 68 * speedScale,
          hp: max(1, (340 * hpScale).round()),
          damage: max(1, (17 * dmgScale).round()),
        ),
      _ => GreatswordSkeletonBossComponent(
          position: pos,
          speed: 66 * speedScale,
          hp: max(1, (350 * hpScale).round()),
          damage: max(1, (18 * dmgScale).round()),
        ),
    };
    worldMap.add(boss);
  }

  /// Описание метода _spawnFinalBoss.
  void _spawnFinalBoss() {
    worldMap.children.whereType<FinalBossComponent>().forEach((b) => b.removeFromParent());
    worldMap.children.whereType<LancerBossComponent>().forEach((b) => b.removeFromParent());

    final p = player;
    if (p == null) return;

    final pos = worldMap.clampToMap(p.position + Vector2(260, -40));
    final (hpScale, dmgScale, speedScale) = _bossScales();

    worldMap.add(
      LancerBossComponent(
        position: pos,
        speed: 78 * speedScale,
        hp: max(1, (420 * hpScale).round()),
        damage: max(1, (20 * dmgScale).round()),
      ),
    );
  }

  /// Описание метода _runProgress.
  double _runProgress() {
    const total = GameConstants.biomeDurationSeconds;
    if (total <= 0) return 0.0;
    final left = timeLeft.value;
    return (1.0 - (left / total)).clamp(0.0, 1.0);
  }

  /// Описание метода _bossScales.
  (double, double, double) _bossScales() {
    final progress = _runProgress();
    final progressCurve = pow(progress, 1.4).toDouble();
    final level = xpSystem.level;
    final mapScale = 1.0 + mapIndex * 0.20;

    final hpScale = (1.0 + progressCurve * 1.0) * (1.0 + max(0, level - 1) * 0.05) * mapScale;
    final dmgScale = (1.0 + progressCurve * 0.6) * (1.0 + max(0, level - 1) * 0.025) * mapScale;
    final speedScale = 1.0 + progressCurve * 0.25 + mapIndex * 0.05;

    return (hpScale, dmgScale, speedScale);
  }

  /// Описание метода mapSeedForIndex.
  int mapSeedForIndex(int index) {
    return seed ^ (index * 1000003);
  }

  /// Описание метода spawnStaticInteractablesForCurrentMap.
  void spawnStaticInteractablesForCurrentMap() {
    worldMap.children.whereType<ChestComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<AltarComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<KeyComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<PortalComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<PotionComponent>().forEach((c) => c.removeFromParent());
    _portal = null;

    final mapRng = Random(mapSeedForIndex(mapIndex));
    final used = <Vector2>[];
    final usedRects = <Rect>[];
    final keyPositions = <Vector2>[];
    final avoidPoint = player?.position ?? (worldMap.mapSize / 2);
    final collisionRects = worldMap.collisionRects;

    final portalSize = Vector2(72, 72);
    final portalPos = _findFreeSizedPoint(
          mapRng,
          used,
          usedRects,
          collisionRects,
          portalSize,
          avoidPoint,
        ) ??
        _randomPointOnMap(mapRng);
    used.add(portalPos);
    usedRects.add(
      Rect.fromCenter(
        center: Offset(portalPos.x, portalPos.y),
        width: portalSize.x,
        height: portalSize.y,
      ),
    );
    final portal = PortalComponent(position: portalPos);
    portal.setLocked(keysFound.value < requiredKeys);
    _portal = portal;
    worldMap.add(portal);

    const keyCount = 2;
    final keySize = Vector2(28, 18);
    for (var i = 0; i < keyCount; i++) {
      final keyPos = _findFreeSizedPoint(
            mapRng,
            used,
            usedRects,
            collisionRects,
            keySize,
            avoidPoint,
            minBetween: GameConstants.keyMinDistanceBetween,
            extraAvoid: keyPositions,
          ) ??
          _findFreeSizedPoint(
            mapRng,
            used,
            usedRects,
            collisionRects,
            keySize,
            avoidPoint,
            minBetween: GameConstants.keyMinDistanceBetween * 0.6,
            extraAvoid: keyPositions,
          ) ??
          _randomPointOnMap(mapRng);
      used.add(keyPos);
      keyPositions.add(keyPos);
      usedRects.add(
        Rect.fromCenter(
          center: Offset(keyPos.x, keyPos.y),
          width: keySize.x,
          height: keySize.y,
        ),
      );
      worldMap.add(KeyComponent(position: keyPos));
    }

    const chestCount = 7;
    final chestSize = Vector2(48, 48);
    final chestPositions = <Vector2>[];
    for (var i = 0; i < chestCount; i++) {
      final pos = _findFreeSizedPoint(
            mapRng,
            used,
            usedRects,
            collisionRects,
            chestSize,
            avoidPoint,
            minBetweenExtra: GameConstants.chestMinDistanceBetween,
            extraAvoid: chestPositions,
          ) ??
          _findFreeSizedPoint(
            mapRng,
            used,
            usedRects,
            collisionRects,
            chestSize,
            avoidPoint,
            minBetweenExtra: GameConstants.chestMinDistanceBetween * 0.7,
            extraAvoid: chestPositions,
          );
      if (pos == null) continue;
      used.add(pos);
      chestPositions.add(pos);
      usedRects.add(
        Rect.fromCenter(
          center: Offset(pos.x, pos.y),
          width: chestSize.x,
          height: chestSize.y,
        ),
      );
      worldMap.add(
        ChestComponent(
          position: pos,
          openTime: 2.0,
          interactRadius: 62,
        ),
      );
    }

    const altarCount = 4;
    final altarSize = Vector2(96 * 0.82, 144 * 0.82);
    final altarPositions = <Vector2>[];
    for (var i = 0; i < altarCount; i++) {
      final pos = _findFreeSizedPoint(
            mapRng,
            used,
            usedRects,
            collisionRects,
            altarSize,
            avoidPoint,
            minBetweenExtra: GameConstants.altarMinDistanceBetween,
            extraAvoid: altarPositions,
          ) ??
          _findFreeSizedPoint(
            mapRng,
            used,
            usedRects,
            collisionRects,
            altarSize,
            avoidPoint,
            minBetweenExtra: GameConstants.altarMinDistanceBetween * 0.7,
            extraAvoid: altarPositions,
          );
      if (pos == null) continue;
      used.add(pos);
      altarPositions.add(pos);
      usedRects.add(
        Rect.fromCenter(
          center: Offset(pos.x, pos.y),
          width: altarSize.x,
          height: altarSize.y,
        ),
      );
      worldMap.add(
        AltarComponent(
          position: pos,
          openTime: 2.2,
          interactRadius: 58,
        ),
      );
    }

    const healPotionCount = 10;
    final potionSize = Vector2.all(20);
    for (var i = 0; i < healPotionCount; i++) {
      final pos = _findFreeSizedPoint(
        mapRng,
        used,
        usedRects,
        collisionRects,
        potionSize,
        avoidPoint,
      );
      if (pos == null) continue;
      used.add(pos);
      usedRects.add(
        Rect.fromCenter(
          center: Offset(pos.x, pos.y),
          width: potionSize.x,
          height: potionSize.y,
        ),
      );
      worldMap.add(
        HealPotionComponent(
          position: pos,
        ),
      );
    }

    const shieldPotionCount = 4;
    for (var i = 0; i < shieldPotionCount; i++) {
      final pos = _findFreeSizedPoint(
        mapRng,
        used,
        usedRects,
        collisionRects,
        potionSize,
        avoidPoint,
      );
      if (pos == null) continue;
      used.add(pos);
      usedRects.add(
        Rect.fromCenter(
          center: Offset(pos.x, pos.y),
          width: potionSize.x,
          height: potionSize.y,
        ),
      );
      worldMap.add(
        ShieldPotionComponent(
          position: pos,
        ),
      );
    }
  }

  /// Описание метода _randomPointOnMap.
  Vector2 _randomPointOnMap(Random r) {
    const margin = 80.0;
    final w = worldMap.mapSize.x;
    final h = worldMap.mapSize.y;

    final x = margin + r.nextDouble() * max(1.0, w - margin * 2);
    final y = margin + r.nextDouble() * max(1.0, h - margin * 2);

    return Vector2(x, y);
  }

  /// Описание метода _findFreeSizedPoint.
  Vector2? _findFreeSizedPoint(
    Random r,
    List<Vector2> used,
    List<Rect> usedRects,
    List<Rect> collisionRects,
    Vector2 size,
    Vector2 avoidPoint, {
    double? minFromPlayer,
    double? minBetween,
    double? minBetweenExtra,
    List<Vector2>? extraAvoid,
  }) {
    final minFromP = minFromPlayer ?? GameConstants.interactableMinDistFromPlayer;
    final minBetweenP = minBetween ?? GameConstants.interactableMinDistBetween;
    final minBetweenExtraP = minBetweenExtra ?? minBetweenP;
    const maxAttempts = GameConstants.interactableSpawnAttempts;

    for (var i = 0; i < maxAttempts; i++) {
      final p = _randomPointOnMap(r);
      if (p.distanceToSquared(avoidPoint) < minFromP * minFromP) {
        continue;
      }

      var ok = true;
      for (final u in used) {
        if (p.distanceToSquared(u) < minBetweenP * minBetweenP) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;

      if (extraAvoid != null) {
        for (final e in extraAvoid) {
          if (p.distanceToSquared(e) < minBetweenExtraP * minBetweenExtraP) {
            ok = false;
            break;
          }
        }
        if (!ok) continue;
      }

      final rect = Rect.fromCenter(
        center: Offset(p.x, p.y),
        width: size.x,
        height: size.y,
      );

      if (_overlapsAny(rect, usedRects)) continue;
      if (_overlapsAny(rect, collisionRects)) continue;

      return p;
    }

    return null;
  }

  bool _overlapsAny(Rect rect, List<Rect> others) {
    for (final other in others) {
      if (rect.overlaps(other)) return true;
    }
    return false;
  }

  /// Описание метода onKeyCollected.
  void onKeyCollected() {
    if (keysFound.value >= requiredKeys) return;
    keysFound.value += 1;
    player?.buffs.emit(const LootCollectedEvent(isKey: true));
    showAnnouncement(l10n.t('key_collected'), seconds: 1.4);

    if (keysFound.value >= requiredKeys) {
      _portal?.setLocked(false);
      showAnnouncement(l10n.t('portal_unlocked'), seconds: 2.2);
    }
  }

  /// Описание метода onPortalCaptured.
  void onPortalCaptured() {
    if (_finalBossSpawned) return;
    _finalBossSpawned = true;
    showAnnouncement(l10n.t('final_boss_spawned'), seconds: 2.6);
    _spawnFinalBoss();
  }

  /// Описание метода onPortalEntered.
  void onPortalEntered() {
    if (_portalTransitionInProgress || !_finalBossDefeated) return;
    _portalTransitionInProgress = true;
    _advanceToNextMap();
    _portalTransitionInProgress = false;
  }

  /// Описание метода _isFirstBoss.
  bool _isFirstBoss(EnemyComponent enemy) {
    return enemy is SkeletonBossComponent ||
        enemy is ArmoredSkeletonBossComponent ||
        enemy is GreatswordSkeletonBossComponent;
  }

  /// Описание метода onEnemyKilled.
  void onEnemyKilled(EnemyComponent enemy) {
    if (_isFirstBoss(enemy) && !_firstBossKeyDropped) {
      _firstBossKeyDropped = true;
      _spawnBossKey(enemy.position);
      showAnnouncement(l10n.t('boss_key_drop'), seconds: 2.0);
    }

    if (enemy is FinalBossComponent && !_finalBossDefeated) {
      _finalBossDefeated = true;
      _portal?.setOpen(true);
      showAnnouncement(l10n.t('portal_open'), seconds: 2.2);
    }
  }

  /// Описание метода _spawnBossKey.
  void _spawnBossKey(Vector2 pos) {
    final dropPos = worldMap.clampToMap(pos + Vector2(32, 0));
    worldMap.add(
      KeyComponent(
        position: dropPos,
        pickupTime: 0.6,
        interactRadius: 64,
      ),
    );
  }

  /// Описание метода _advanceToNextMap.
  void _advanceToNextMap() {
    mapIndex += 1;
    keysFound.value = 0;
    _firstBossSpawned = false;
    _firstBossWarned = false;
    _firstBossKeyDropped = false;
    _finalBossSpawned = false;
    _finalBossDefeated = false;
    _swarmSpawned = false;
    _swarmWarned = false;
    _portal = null;

    clearBossHud();
    _announcementTimer?.cancel();
    _announcementTimer = null;
    announcementText.value = '';

    worldMap.children.whereType<EnemyComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<XpCrystalComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<ChestComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<AltarComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<KeyComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<PortalComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<PotionComponent>().forEach((c) => c.removeFromParent());

    final p = player;
    if (p != null) {
      p.position = worldMap.mapSize / 2;
    }

    biomeTimer.resetAndStart();
    enemySpawner.isPaused = false;

    spawnStaticInteractablesForCurrentMap();
    showAnnouncement(l10n.t('map_next'), seconds: 2.0);
  }

  // ===== rewards entrypoints =====

  /// Описание метода onChestOpened.
  Future<void> onChestOpened() async {
    _enqueueRewardOverlay(RewardSource.chest);
  }

  /// Описание метода onAltarActivated.
  Future<void> onAltarActivated() async {
    _enqueueRewardOverlay(RewardSource.altar);
  }

  /// Описание метода showBossReward.
  void showBossReward() {
    _enqueueRewardOverlay(RewardSource.boss);
  }

  Future<List<RewardDefinition>> _rollRewardsWithGuarantees({
    required RewardSource source,
    required int count,
    required double luckBonus,
    Set<String>? excludeIds,
    Rarity? minRarity,
  }) async {
    final result = <RewardDefinition>[];
    final localExcluded = <String>{};
    if (excludeIds != null) {
      localExcluded.addAll(excludeIds);
    }
    var remaining = count;

    Future<List<RewardDefinition>> rollOnce({
      required int rollCount,
      RewardKind? requiredKind,
      Rarity? requiredRarity,
    }) async {
      final rolled = await rewardRepository.roll(
        source: source,
        count: rollCount,
        rng: rng,
        l10n: l10n,
        game: this,
        build: buildState,
        luckBonus: luckBonus,
        excludeIds: localExcluded,
        minRarity: requiredRarity == null ? minRarity : null,
        requiredKind: requiredKind,
        requiredRarity: requiredRarity,
      );
      for (final r in rolled) {
        localExcluded.add(r.id);
      }
      result.addAll(rolled);
      return rolled;
    }

    if (source != RewardSource.boss && _legendaryNoHitStreak >= 8 && remaining > 0) {
      final forced = await rollOnce(rollCount: 1, requiredRarity: Rarity.legendary);
      if (forced.isNotEmpty) remaining -= 1;
    }

    if (source == RewardSource.altar && _altarNoAbilityStreak >= 2 && remaining > 0) {
      final alreadyHasAbility = result.any((r) => r.kind == RewardKind.ability);
      if (!alreadyHasAbility) {
        final forced = await rollOnce(rollCount: 1, requiredKind: RewardKind.ability);
        if (forced.isNotEmpty) remaining -= 1;
      }
    }

    if (remaining > 0) {
      await rollOnce(rollCount: remaining);
    }

    return result;
  }

  /// Описание метода _openRewardOverlay.
  Future<void> _openRewardOverlay(RewardSource source) async {
    // Готовим показ награды и включаем паузу, если она еще не активна.
    _rewardOverlayOpen = true;
    if (!_rewardPauseLock) {
      _rewardPauseLock = true;
      pauseEngine();
    }

    final count = (source == RewardSource.chest || source == RewardSource.boss) ? 1 : 3;
    final luckBonus = switch (source) {
      RewardSource.levelUp => runModifiers.luckBonusLevelUp,
      RewardSource.altar => runModifiers.luckBonusAltar,
      _ => 0.0,
    };

    final excludeIds = switch (source) {
      RewardSource.chest => _chestSeenRewardIds,
      RewardSource.boss => _bossSeenRewardIds,
      _ => null,
    };
    final minRarity = source == RewardSource.chest && _chestCommonStreak >= 4 ? Rarity.rare : null;

    final rolled = await _rollRewardsWithGuarantees(
      source: source,
      count: count,
      luckBonus: luckBonus,
      excludeIds: excludeIds,
      minRarity: minRarity,
    );

    // Если наград нет, закрываем цикл и идем дальше.
    if (rolled.isEmpty) {
      _finishRewardOverlay();
      return;
    }

    if (source == RewardSource.chest) {
      for (final reward in rolled) {
        _chestSeenRewardIds.add(reward.id);
      }
      if (rolled.first.rarity == Rarity.common) {
        _chestCommonStreak += 1;
      } else {
        _chestCommonStreak = 0;
      }
    }

    if (source == RewardSource.altar) {
      final hasAbility = rolled.any((r) => r.kind == RewardKind.ability);
      if (hasAbility) {
        _altarNoAbilityStreak = 0;
      } else {
        _altarNoAbilityStreak += 1;
      }
    }

    final hasLegendary = rolled.any((r) => r.rarity == Rarity.legendary);
    if (hasLegendary) {
      _legendaryNoHitStreak = 0;
    } else {
      _legendaryNoHitStreak += 1;
    }

    if (source == RewardSource.boss) {
      for (final reward in rolled) {
        _bossSeenRewardIds.add(reward.id);
      }
      bossRewardChoice.value = rolled.first;
      if (!overlays.isActive(Overlays.bossReward)) {
        overlays.add(Overlays.bossReward);
      }
    } else {
      rewardChoices.value = rolled;
      if (!overlays.isActive(Overlays.rewardPick)) {
        overlays.add(Overlays.rewardPick);
      }
    }
  }

  /// Описание метода applyRewardAndResume.
  void applyRewardAndResume(RewardDefinition reward) {
    reward.apply(this);
    if (reward.kind == RewardKind.item) {
      player?.buffs.emit(const LootCollectedEvent(isKey: false));
    }

    overlays.remove(Overlays.rewardPick);
    rewardChoices.value = <RewardDefinition>[];

    _finishRewardOverlay();
  }

  /// Описание метода applyBossRewardAndResume.
  void applyBossRewardAndResume() {
    final reward = bossRewardChoice.value;
    if (reward == null) return;

    reward.apply(this);
    if (reward.kind == RewardKind.item) {
      player?.buffs.emit(const LootCollectedEvent(isKey: false));
    }

    overlays.remove(Overlays.bossReward);
    bossRewardChoice.value = null;

    _finishRewardOverlay();
  }

  /// Описание метода skipRewardAndResume.
  void skipRewardAndResume() {
    overlays.remove(Overlays.rewardPick);
    rewardChoices.value = <RewardDefinition>[];

    _finishRewardOverlay();
  }

  // ===== HUD sync / lifecycle =====

  /// Описание метода _syncPlayerStatsToHud.
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

  /// Описание метода _onBiomeTimeChanged.
  void _onBiomeTimeChanged(double t) {
    timeLeft.value = t;

    if (!_firstBossWarned &&
        t <=
            GameConstants.firstBossSpawnTimeLeftSeconds +
                GameConstants.firstBossWarningLeadSeconds &&
        t > GameConstants.firstBossSpawnTimeLeftSeconds) {
      _firstBossWarned = true;
      showAnnouncement(
        l10n.t('boss_warning'),
        seconds: GameConstants.firstBossWarningLeadSeconds,
      );
    }

    if (!_swarmWarned &&
        t <= GameConstants.swarmTimeLeftSeconds + GameConstants.swarmWarningLeadSeconds &&
        t > GameConstants.swarmTimeLeftSeconds) {
      _swarmWarned = true;
      showAnnouncement(l10n.t('swarm_warning'), seconds: GameConstants.swarmWarningLeadSeconds);
    }

    if (!_swarmSpawned && t <= GameConstants.swarmTimeLeftSeconds) {
      _swarmSpawned = true;
      final count = GameConstants.swarmSpawnBaseCount +
          (threatSystem.level * GameConstants.swarmSpawnThreatBonus);
      enemySpawner.spawnSwarm(
        count: count,
        eliteChanceBonus: GameConstants.swarmEliteChanceBonus,
      );
    }

    if (_firstBossSpawned) return;
    if (t > GameConstants.firstBossSpawnTimeLeftSeconds) return;

    _firstBossSpawned = true;
    _spawnFirstBoss();
  }

  /// Описание метода showAnnouncement.
  void showAnnouncement(String text, {double seconds = 2.0}) {
    announcementText.value = text;
    _announcementTimer?.cancel();
    _announcementTimer = Timer(
      Duration(milliseconds: (seconds * 1000).round()),
      () => announcementText.value = '',
    );
  }

  /// Описание метода setBossHud.
  void setBossHud(String name, int hp, int maxHp) {
    bossName.value = name;
    bossHp.value = hp;
    bossMaxHp.value = maxHp;
  }

  /// Описание метода clearBossHud.
  void clearBossHud() {
    bossName.value = '';
    bossHp.value = 0;
    bossMaxHp.value = 0;
  }

  /// Описание метода assignAbilitySlot.
  void assignAbilitySlot(String abilityId) {
    final list = List<String?>.from(abilitySlots.value);
    if (list.contains(abilityId)) return;

    final idx = list.indexOf(null);
    if (idx == -1) return;

    list[idx] = abilityId;
    abilitySlots.value = list;
  }

  /// Описание метода tryActivateAbilitySlot.
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

  /// Описание метода notifyPlayerStatsChanged.
  void notifyPlayerStatsChanged() => _syncPlayerStatsToHud();

  /// Описание метода onPlayerDied.
  void onPlayerDied() {
    enemySpawner.isPaused = true;

    joystick.delta.setZero();
    joystick.relativeDelta.setZero();

    _syncPlayerStatsToHud();

    overlays.add(Overlays.heroSelect);
  }

  /// Описание метода _onBiomeTimeOver.
  void _onBiomeTimeOver() {
    enemySpawner.isPaused = true;
    overlays.add(Overlays.heroSelect);
  }

  /// Описание метода _enqueueRewardOverlay.
  void _enqueueRewardOverlay(RewardSource source) {
    if (_rewardOverlayOpen ||
        overlays.isActive(Overlays.rewardPick) ||
        overlays.isActive(Overlays.bossReward)) {
      _rewardQueue.add(source);
      return;
    }

    unawaited(_openRewardOverlay(source));
  }

  /// Описание метода _finishRewardOverlay.
  void _finishRewardOverlay() {
    _rewardOverlayOpen = false;

    if (_rewardQueue.isNotEmpty) {
      final next = _rewardQueue.removeAt(0);
      unawaited(_openRewardOverlay(next));
      return;
    }

    _rewardPauseLock = false;
    resumeEngine();
  }

  /// Описание метода findNearestEnemyInRadius.
  EnemyComponent? findNearestEnemyInRadius(
    Vector2 center,
    double radius, {
    Set<EnemyComponent>? exclude,
    bool requireLineOfSight = true,
  }) {
    final r2 = radius * radius;

    EnemyComponent? best;
    double bestD2 = double.infinity;

    for (final c in worldMap.children) {
      if (c is! EnemyComponent) continue;
      if (c.isDead || c.isRemoving) continue;
      if (exclude != null && exclude.contains(c)) continue;

      if (requireLineOfSight && !worldMap.hasLineOfSight(center, c.position)) {
        continue;
      }

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
  /// Описание метода setLocaleRu.
  void setLocaleRu() => l10n.setLocale(AppLocale.ru);

  /// Описание метода setLocaleEn.
  void setLocaleEn() => l10n.setLocale(AppLocale.en);

  @override

  /// Описание метода onRemove.
  void onRemove() {
    // Закрываем DB при выгрузке игры.
    unawaited(db.close());
    super.onRemove();
  }
}
