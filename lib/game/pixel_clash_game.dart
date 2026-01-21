import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/active_ability.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/enemies/types/skeleton_boss.dart';
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

  // Boss HUD
  final ValueNotifier<int> bossHp = ValueNotifier<int>(0);
  final ValueNotifier<int> bossMaxHp = ValueNotifier<int>(0);
  final ValueNotifier<String> bossName = ValueNotifier<String>('');
  final ValueNotifier<String> announcementText = ValueNotifier<String>('');

  /// Слоты активных способностей (id или null).
  final ValueNotifier<List<String?>> abilitySlots =
      ValueNotifier<List<String?>>(List<String?>.filled(4, null));

  final ValueNotifier<int> level = ValueNotifier<int>(1);
  final ValueNotifier<double> xpProgress = ValueNotifier<double>(0);

  final ValueNotifier<List<RewardDefinition>> rewardChoices =
      ValueNotifier<List<RewardDefinition>>(<RewardDefinition>[]);
  final ValueNotifier<RewardDefinition?> bossRewardChoice = ValueNotifier<RewardDefinition?>(null);
  final List<RewardSource> _rewardQueue = <RewardSource>[];
  bool _rewardOverlayOpen = false;

  // ===== Build/Upgrades =====
  late final AppDatabase db;
  late final UpgradeRegistry upgradeRegistry;
  late final PlayerBuildState buildState;
  late final RewardRepository rewardRepository;
  final RunModifiers runModifiers = RunModifiers();

  // ===== HIT-STOP =====
  bool _hitStopInProgress = false;
  double _hitStopCooldown = 0;
  bool _bossSpawned = false;
  bool _bossWarned = false;
  Timer? _announcementTimer;

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

  /// Нужен для жёсткой паузы логики поверх оверлеев наград.
  bool get isRewardPauseActive => _rewardPauseLock;

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
    _bossSpawned = false;
    _bossWarned = false;
    clearBossHud();
    _announcementTimer?.cancel();
    _announcementTimer = null;
    announcementText.value = '';

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
    overlays.remove(Overlays.bossReward);
    bossRewardChoice.value = null;
    _rewardQueue.clear();
    _rewardOverlayOpen = false;
    _rewardPauseLock = false;

    _hitStopInProgress = false;
    _hitStopCooldown = 0;

    resumeEngine();
  }

  void _spawnMainBoss() {
    // ??????? ???????? ????? ?? ?????.
    worldMap.children.whereType<SkeletonBossComponent>().forEach((b) => b.removeFromParent());

    final p = player;
    if (p == null) return;

    final pos = worldMap.clampToMap(p.position + Vector2(220, 0));

    worldMap.add(
      SkeletonBossComponent(
        position: pos,
        speed: 70,
        hp: 10,
        damage: 14,
        scoreReward: 40,
        xpReward: 30,
      ),
    );
  }

  int mapSeedForIndex(int index) {
    return seed ^ (index * 1000003);
  }

  void spawnStaticInteractablesForCurrentMap() {
    worldMap.children.whereType<ChestComponent>().forEach((c) => c.removeFromParent());
    worldMap.children.whereType<AltarComponent>().forEach((c) => c.removeFromParent());

    final mapRng = Random(mapSeedForIndex(mapIndex));
    final used = <Vector2>[];
    final avoidPoint = player?.position ?? (worldMap.mapSize / 2);

    const chestCount = 100;
    for (var i = 0; i < chestCount; i++) {
      final pos = _findFreeInteractablePoint(mapRng, used, avoidPoint);
      if (pos == null) continue;
      used.add(pos);
      worldMap.add(
        ChestComponent(
          position: pos,
          openTime: 2.0,
          interactRadius: 54,
        ),
      );
    }

    const altarCount = 100;
    for (var i = 0; i < altarCount; i++) {
      final pos = _findFreeInteractablePoint(mapRng, used, avoidPoint);
      if (pos == null) continue;
      used.add(pos);
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

  Vector2? _findFreeInteractablePoint(Random r, List<Vector2> used, Vector2 avoidPoint) {
    const minFromPlayer = GameConstants.interactableMinDistFromPlayer;
    const minBetween = GameConstants.interactableMinDistBetween;
    const maxAttempts = GameConstants.interactableSpawnAttempts;

    for (var i = 0; i < maxAttempts; i++) {
      final p = _randomPointOnMap(r);
      if (p.distanceToSquared(avoidPoint) < minFromPlayer * minFromPlayer) {
        continue;
      }

      var ok = true;
      for (final u in used) {
        if (p.distanceToSquared(u) < minBetween * minBetween) {
          ok = false;
          break;
        }
      }

      if (ok) return p;
    }

    return null;
  }

  // ===== rewards entrypoints =====

  Future<void> onChestOpened() async {
    _enqueueRewardOverlay(RewardSource.chest);
  }

  Future<void> onAltarActivated() async {
    _enqueueRewardOverlay(RewardSource.altar);
  }

  /// Отдельный оверлей для награды босса.
  void showBossReward() {
    _enqueueRewardOverlay(RewardSource.boss);
  }

  /// Унифицированная точка показа наград.
  /// Важно:
  /// - сначала ставим игру на паузу
  /// - потом роллим награды
  /// - если наград нет => паузу снимаем и ничего не показываем
  Future<void> _openRewardOverlay(RewardSource source) async {
    // Готовим показ награды и включаем паузу, если она еще не активна.
    _rewardOverlayOpen = true;
    if (!_rewardPauseLock) {
      _rewardPauseLock = true;
      pauseEngine();
    }

    final count = (source == RewardSource.chest || source == RewardSource.boss) ? 1 : 3;
    final rolled = await rewardRepository.roll(
      source: source,
      count: count,
      rng: rng,
      l10n: l10n,
      game: this,
      build: buildState,
      luckBonus: runModifiers.luckBonus,
    );

    // Если наград нет, закрываем цикл и идем дальше.
    if (rolled.isEmpty) {
      _finishRewardOverlay();
      return;
    }

    if (source == RewardSource.boss) {
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

  /// Вызывается UI после выбора карточки.
  void applyRewardAndResume(RewardDefinition reward) {
    reward.apply(this);

    overlays.remove(Overlays.rewardPick);
    rewardChoices.value = <RewardDefinition>[];

    _finishRewardOverlay();
  }

  void applyBossRewardAndResume() {
    final reward = bossRewardChoice.value;
    if (reward == null) return;

    reward.apply(this);

    overlays.remove(Overlays.bossReward);
    bossRewardChoice.value = null;

    _finishRewardOverlay();
  }

  void skipRewardAndResume() {
    overlays.remove(Overlays.rewardPick);
    rewardChoices.value = <RewardDefinition>[];

    _finishRewardOverlay();
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

  void _onBiomeTimeChanged(double t) {
    timeLeft.value = t;

    if (!_bossWarned &&
        t <= GameConstants.bossSpawnTimeLeftSeconds + GameConstants.bossWarningLeadSeconds &&
        t > GameConstants.bossSpawnTimeLeftSeconds) {
      _bossWarned = true;
      showAnnouncement(l10n.t('boss_warning'), seconds: GameConstants.bossWarningLeadSeconds);
    }

    if (_bossSpawned) return;
    if (t > GameConstants.bossSpawnTimeLeftSeconds) return;

    _bossSpawned = true;
    _spawnMainBoss();
  }

  void showAnnouncement(String text, {double seconds = 2.0}) {
    announcementText.value = text;
    _announcementTimer?.cancel();
    _announcementTimer = Timer(
      Duration(milliseconds: (seconds * 1000).round()),
      () => announcementText.value = '',
    );
  }

  void setBossHud(String name, int hp, int maxHp) {
    bossName.value = name;
    bossHp.value = hp;
    bossMaxHp.value = maxHp;
  }

  void clearBossHud() {
    bossName.value = '';
    bossHp.value = 0;
    bossMaxHp.value = 0;
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

  void _enqueueRewardOverlay(RewardSource source) {
    if (_rewardOverlayOpen ||
        overlays.isActive(Overlays.rewardPick) ||
        overlays.isActive(Overlays.bossReward)) {
      _rewardQueue.add(source);
      return;
    }

    unawaited(_openRewardOverlay(source));
  }

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
