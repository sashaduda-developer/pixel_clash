import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/player/attack_profile.dart';
import 'package:pixel_clash/game/components/player/hero_type.dart';
import 'package:pixel_clash/game/components/player/hero_visuals.dart';
import 'package:pixel_clash/game/components/player/player_attack_behavior.dart';
import 'package:pixel_clash/game/components/player/player_stats.dart';

class HeroDefinition {
  HeroDefinition({
    required this.type,
    required this.id,
    required this.titleKey,
    required this.subtitleKey,
    required this.statsFactory,
    required this.attackProfile,
    required this.visuals,
    required this.attackBehavior,
  });

  final HeroType type;
  final String id;
  final String titleKey;
  final String subtitleKey;
  final PlayerStats Function() statsFactory;
  final AttackProfile attackProfile;
  final HeroVisualConfig visuals;
  final PlayerAttackBehavior attackBehavior;

  PlayerStats createStats() => statsFactory();
}

class HeroCatalog {
  HeroCatalog._();

  static const String legacySamuraiId = 'ninja';

  static final List<HeroDefinition> _heroes = <HeroDefinition>[
    HeroDefinition(
      type: HeroType.ranger,
      id: 'ranger',
      titleKey: 'hero_ranger_title',
      subtitleKey: 'hero_ranger_subtitle',
      statsFactory: _rangerStats,
      attackProfile: const AttackProfile(
        range: 420,
        meleeRadius: 0,
        projectileSpeed: 520,
        projectileColor: Color(0xFFFFD54F),
        projectileSize: Size(18, 4),
        samuraiHits: 0,
        samuraiHitDelaySec: 0,
      ),
      visuals: HeroVisualConfig(
        baseColor: const Color(0xFF42A5F5),
        spriteScale: 1.6,
        spriteSize: 100,
        idle: _anim('characters/Archer/Archer-Idle.png', 6, 0.12),
        walk: _anim('characters/Archer/Archer-Walk.png', 8, 0.09),
        attack: _anim('characters/Archer/Archer-Attack.png', 6, 0.07),
        hurt: _anim('characters/Archer/Archer-Hurt.png', 4, 0.07),
        death: _anim('characters/Archer/Archer-Death.png', 6, 0.12, loop: false),
        arrowProjectile: const ProjectileAssetConfig(
          assetPath: 'characters/Archer/Arrow.png',
          renderSize: Size(32, 32),
        ),
      ),
      attackBehavior: const RangerAttackBehavior(),
    ),
    HeroDefinition(
      type: HeroType.knight,
      id: 'knight',
      titleKey: 'hero_knight_title',
      subtitleKey: 'hero_knight_subtitle',
      statsFactory: _knightStats,
      attackProfile: const AttackProfile(
        range: 100,
        meleeRadius: 80,
        projectileSpeed: 420,
        projectileColor: Color(0xFFFFB74D),
        projectileSize: Size(26, 6),
        samuraiHits: 0,
        samuraiHitDelaySec: 0,
      ),
      visuals: HeroVisualConfig(
        baseColor: const Color(0xFF66BB6A),
        spriteScale: 1.6,
        spriteSize: 100,
        idle: _anim('characters/Knight/Knight-Idle.png', 6, 0.12),
        walk: _anim('characters/Knight/Knight-Walk.png', 8, 0.09),
        attack: _anim('characters/Knight/Knight-Attack.png', 6, 0.07),
        hurt: _anim('characters/Knight/Knight-Hurt.png', 4, 0.07),
        death: _anim('characters/Knight/Knight-Death.png', 6, 0.12, loop: false),
      ),
      attackBehavior: const KnightAttackBehavior(),
    ),
    HeroDefinition(
      type: HeroType.mage,
      id: 'mage',
      titleKey: 'hero_mage_title',
      subtitleKey: 'hero_mage_subtitle',
      statsFactory: _mageStats,
      attackProfile: const AttackProfile(
        range: 480,
        meleeRadius: 0,
        projectileSpeed: 360,
        projectileColor: Color(0xFFFF8A65),
        projectileSize: Size(22, 22),
        samuraiHits: 0,
        samuraiHitDelaySec: 0,
      ),
      visuals: HeroVisualConfig(
        baseColor: const Color(0xFF26C6DA),
        spriteScale: 1.6,
        spriteSize: 100,
        idle: _anim('characters/Wizard/Wizard-Idle.png', 6, 0.12),
        walk: _anim('characters/Wizard/Wizard-Walk.png', 8, 0.09),
        attack: _anim('characters/Wizard/Wizard-Attack.png', 6, 0.07),
        hurt: _anim('characters/Wizard/Wizard-Hurt.png', 4, 0.07),
        death: _anim('characters/Wizard/Wizard-Death.png', 6, 0.12, loop: false),
        fireballProjectile: const ProjectileAssetConfig(
          assetPath: 'characters/Wizard/Fireball.png',
          renderSize: Size(48, 48),
          frameSize: Size(100, 100),
          frames: 4,
          stepTime: 0.07,
          buildAnimation: true,
        ),
      ),
      attackBehavior: const MageAttackBehavior(),
    ),
    HeroDefinition(
      type: HeroType.samurai,
      id: 'samurai',
      titleKey: 'hero_samurai_title',
      subtitleKey: 'hero_samurai_subtitle',
      statsFactory: _samuraiStats,
      attackProfile: const AttackProfile(
        range: 100,
        meleeRadius: 80,
        projectileSpeed: 0,
        projectileColor: Color(0xFFFFFFFF),
        projectileSize: Size(0, 0),
        samuraiHits: 2,
        samuraiHitDelaySec: 0.06,
      ),
      visuals: HeroVisualConfig(
        baseColor: const Color(0xFFEF5350),
        spriteScale: 1.6,
        spriteSize: 100,
        idle: _anim('characters/Swordsman/Swordsman-Idle.png', 6, 0.12),
        walk: _anim('characters/Swordsman/Swordsman-Walk.png', 8, 0.09),
        attack: _anim('characters/Swordsman/Swordsman-Attack.png', 7, 0.05),
        hurt: _anim('characters/Swordsman/Swordsman-Hurt.png', 5, 0.07),
        death: _anim('characters/Swordsman/Swordsman-Death.png', 4, 0.12, loop: false),
      ),
      attackBehavior: const SamuraiAttackBehavior(),
    ),
  ];

  static final Map<HeroType, HeroDefinition> _byType = <HeroType, HeroDefinition>{
    for (final hero in _heroes) hero.type: hero,
  };

  static final Map<String, HeroDefinition> _byId = <String, HeroDefinition>{
    for (final hero in _heroes) hero.id: hero,
    legacySamuraiId: _heroes.firstWhere((h) => h.type == HeroType.samurai),
  };

  static List<HeroDefinition> get all => List<HeroDefinition>.unmodifiable(_heroes);

  static HeroDefinition forType(HeroType type) => _byType[type]!;

  static HeroDefinition? byId(String id) => _byId[id];

  static String idForType(HeroType type) => forType(type).id;

  static HeroType? typeForId(String id) => _byId[id]?.type;

  static bool isAlias(String stored, String current) {
    if (stored == current) return true;
    if (stored == legacySamuraiId && current == 'samurai') return true;
    if (stored == 'samurai' && current == legacySamuraiId) return true;
    return false;
  }
}

AnimationAssetConfig _anim(
  String path,
  int frames,
  double stepTime, {
  bool loop = true,
}) {
  return AnimationAssetConfig(
    assetPath: path,
    frames: frames,
    stepTime: stepTime,
    frameSize: const Size(100, 100),
    loop: loop,
  );
}

PlayerStats _rangerStats() {
  return PlayerStats(
    maxHp: 70,
    hp: 70,
    armor: 0,
    damage: 10,
    attackSpeed: 1.2,
    moveSpeed: 190,
    maxMana: 100,
    mana: 100,
    manaRegen: 2.2,
    hpRegen: 0.0,
    evasionChance: 0.0,
    critChance: 0.15,
    critMultiplier: 1.8,
  );
}

PlayerStats _knightStats() {
  return PlayerStats(
    maxHp: 110,
    hp: 110,
    armor: 2,
    damage: 14,
    attackSpeed: 0.9,
    moveSpeed: 165,
    maxMana: 90,
    mana: 90,
    manaRegen: 2.5,
    hpRegen: 0.0,
    evasionChance: 0.0,
    critChance: 0.15,
    critMultiplier: 1.8,
  );
}

PlayerStats _mageStats() {
  return PlayerStats(
    maxHp: 60,
    hp: 60,
    armor: 0,
    damage: 12,
    attackSpeed: 0.75,
    moveSpeed: 175,
    maxMana: 140,
    mana: 140,
    manaRegen: 2.0,
    hpRegen: 0.0,
    evasionChance: 0.0,
    critChance: 0.12,
    critMultiplier: 1.7,
  );
}

PlayerStats _samuraiStats() {
  return PlayerStats(
    maxHp: 65,
    hp: 65,
    armor: 0,
    damage: 9,
    attackSpeed: 1.45,
    moveSpeed: 215,
    maxMana: 80,
    mana: 80,
    manaRegen: 2.4,
    hpRegen: 0.0,
    evasionChance: 0.10,
    critChance: 0.18,
    critMultiplier: 1.7,
  );
}
