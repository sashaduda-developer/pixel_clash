import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/buff_system.dart';
import 'package:pixel_clash/game/components/combat/buffs/altar_buffs.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/melee_slash_effect.dart';
import 'package:pixel_clash/game/components/combat/projectile_arrow.dart';
import 'package:pixel_clash/game/components/enemies/enemy_component.dart';
import 'package:pixel_clash/game/components/player/attack_profile.dart';
import 'package:pixel_clash/game/components/player/player_stats.dart';

abstract class PlayerAttackContext {
  PositionComponent get owner;
  Vector2 get position;
  PlayerStats get stats;
  AttackProfile get attackProfile;
  BuffSystem get buffs;

  EnemyComponent? findNearestEnemyInRange({
    required bool onlyVisibleOnScreen,
    required double range,
  });

  void setFacingForAttack(Vector2 dir);
  void triggerAttackAnimation();
  double attackImpactDelaySec();
  void scheduleAttackImpact({required double delay, required void Function() action});
  (int, bool) rollDamage();
  bool rollChance(double chance);
  void shootProjectile({
    required Vector2 direction,
    required int damage,
    required bool isCrit,
    required double speed,
    required Color color,
    required Size size,
    required DamageSourceType sourceType,
    ProjectileVisual visual,
    int? pierceOverride,
    int? ricochetOverride,
    double? ricochetMultiplierOverride,
    Sprite? spriteOverride,
    SpriteAnimation? spriteAnimationOverride,
    double? angleOffset,
  });

  void addWorldComponent(Component component);
  void notifyStatsChanged();
  void setAttackTimer(double value);

  Sprite? get arrowSprite;
  Size? get arrowSpriteSize;
  Sprite? get fireballSprite;
  SpriteAnimation? get fireballAnimation;
  Size? get fireballSpriteSize;
}

abstract class PlayerAttackBehavior {
  const PlayerAttackBehavior();
  bool tryAttack(PlayerAttackContext context);
}

class RangerAttackBehavior extends PlayerAttackBehavior {
  const RangerAttackBehavior({this.arrowAngleOffset = 0.0});

  final double arrowAngleOffset;

  @override
  bool tryAttack(PlayerAttackContext context) {
    final target = context.findNearestEnemyInRange(
      onlyVisibleOnScreen: true,
      range: context.attackProfile.range,
    );
    if (target == null) return false;

    context.setFacingForAttack(target.position - context.position);
    context.triggerAttackAnimation();
    context.scheduleAttackImpact(
      delay: context.attackImpactDelaySec(),
      action: () {
        if (target.isRemoving || target.isDead) return;
        final dir = (target.position - context.position);
        if (dir.length2 <= 0.0001) return;

        final (dmg, isCrit) = context.rollDamage();
        final projectileSize = (context.arrowSprite != null && context.arrowSpriteSize != null)
            ? context.arrowSpriteSize!
            : context.attackProfile.projectileSize;

        context.shootProjectile(
          direction: dir,
          damage: dmg,
          isCrit: isCrit,
          speed: context.attackProfile.projectileSpeed,
          color: context.attackProfile.projectileColor,
          size: projectileSize,
          sourceType: DamageSourceType.arrow,
          spriteOverride: context.arrowSprite,
          angleOffset: arrowAngleOffset,
        );
      },
    );
    return true;
  }
}

class MageAttackBehavior extends PlayerAttackBehavior {
  const MageAttackBehavior();

  @override
  bool tryAttack(PlayerAttackContext context) {
    final target = context.findNearestEnemyInRange(
      onlyVisibleOnScreen: true,
      range: context.attackProfile.range,
    );
    if (target == null) return false;

    context.setFacingForAttack(target.position - context.position);
    context.triggerAttackAnimation();
    context.scheduleAttackImpact(
      delay: context.attackImpactDelaySec(),
      action: () {
        if (target.isRemoving || target.isDead) return;
        final dir = (target.position - context.position);
        if (dir.length2 <= 0.0001) return;

        var (dmg, isCrit) = context.rollDamage();
        final manaBuff =
            context.buffs.getBuffAs<MageManaSurgeBuff>('buff_mage_mana_surge');
        if (manaBuff != null) {
          final cost = manaBuff.manaCost;
          if (cost > 0 && !context.stats.spendMana(cost)) return;
          if (cost > 0) context.notifyStatsChanged();

          dmg = (dmg * manaBuff.damageMultiplier).round().clamp(1, 999999);
        }

        final projectileSize =
            (context.fireballSprite != null && context.fireballSpriteSize != null)
                ? context.fireballSpriteSize!
                : context.attackProfile.projectileSize;

        context.shootProjectile(
          direction: dir,
          damage: dmg,
          isCrit: isCrit,
          speed: context.attackProfile.projectileSpeed,
          color: context.attackProfile.projectileColor,
          size: projectileSize,
          sourceType: DamageSourceType.ability,
          visual: ProjectileVisual.fireball,
          spriteOverride: context.fireballSprite,
          spriteAnimationOverride: context.fireballAnimation,
        );
      },
    );
    return true;
  }
}

class KnightAttackBehavior extends PlayerAttackBehavior {
  const KnightAttackBehavior();

  @override
  bool tryAttack(PlayerAttackContext context) {
    final target = context.findNearestEnemyInRange(
      onlyVisibleOnScreen: false,
      range: context.attackProfile.range,
    );
    if (target == null) return false;

    context.setFacingForAttack(target.position - context.position);
    context.triggerAttackAnimation();
    context.scheduleAttackImpact(
      delay: context.attackImpactDelaySec(),
      action: () {
        if (target.isRemoving || target.isDead) return;
        final dir = (target.position - context.position);
        if (dir.length2 <= 0.0001) return;

        final meleeRadius = context.attackProfile.meleeRadius;
        if (meleeRadius <= 0 || dir.length2 > meleeRadius * meleeRadius) return;

        final (dmg, isCrit) = context.rollDamage();
        _applyMeleeHit(
          context,
          target: target,
          damage: dmg,
          isCrit: isCrit,
          slashColor: const Color(0xFFFFF3E0),
          slashLength: 44,
          slashThickness: 5,
          slashMaxAlpha: 0.85,
        );
      },
    );
    return true;
  }
}

class SamuraiAttackBehavior extends PlayerAttackBehavior {
  const SamuraiAttackBehavior({
    this.secondImpactFactor = 0.55,
    this.reachBonus = 8.0,
    this.comboCooldown = 0.18,
    this.secondDamageScale = 0.8,
    this.slashColor = const Color(0xFFFFF3E0),
  });

  final double secondImpactFactor;
  final double reachBonus;
  final double comboCooldown;
  final double secondDamageScale;
  final Color slashColor;

  @override
  bool tryAttack(PlayerAttackContext context) {
    final target = context.findNearestEnemyInRange(
      onlyVisibleOnScreen: false,
      range: context.attackProfile.range,
    );
    if (target == null) return false;

    context.setFacingForAttack(target.position - context.position);
    context.triggerAttackAnimation();
    final impactDelay = context.attackImpactDelaySec();
    context.scheduleAttackImpact(
      delay: impactDelay,
      action: () {
        if (target.isRemoving || target.isDead) return;
        final (dmg, isCrit) = context.rollDamage();
        _samuraiStrike(
          context,
          target: target,
          baseDamage: dmg,
          isCrit: isCrit,
          radius: context.attackProfile.meleeRadius,
          allowCrit: true,
        );

        if (context.attackProfile.samuraiHits <= 1) return;
        final cooldown = comboCooldown / max(0.2, context.stats.attackSpeed);
        context.setAttackTimer(-cooldown);
        context.scheduleAttackImpact(
          delay: context.attackProfile.samuraiHitDelaySec,
          action: () {
            if (target.isRemoving || target.isDead) return;
            context.triggerAttackAnimation();
            context.scheduleAttackImpact(
              delay: context.attackImpactDelaySec() * secondImpactFactor,
              action: () {
                if (target.isRemoving || target.isDead) return;
                _samuraiStrike(
                  context,
                  target: target,
                  baseDamage: dmg,
                  isCrit: false,
                  radius: context.attackProfile.meleeRadius * 0.9,
                  damageScale: secondDamageScale,
                  allowCrit: false,
                );

                final tripleBuff = context.buffs
                    .getBuffAs<SamuraiTripleStrikeBuff>('buff_samurai_triple_strike');
                final chance = tripleBuff?.thirdHitChance ?? 0.0;
                if (chance <= 0 || !context.rollChance(chance)) return;

                context.triggerAttackAnimation();
                context.scheduleAttackImpact(
                  delay: context.attackImpactDelaySec() * secondImpactFactor,
                  action: () {
                    if (target.isRemoving || target.isDead) return;
                    _samuraiStrike(
                      context,
                      target: target,
                      baseDamage: dmg,
                      isCrit: false,
                      radius: context.attackProfile.meleeRadius * 0.9,
                      damageScale: tripleBuff?.thirdHitDamageMultiplier ?? 0.8,
                      allowCrit: false,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
    return true;
  }

  void _samuraiStrike(
    PlayerAttackContext context, {
    required EnemyComponent target,
    required int baseDamage,
    required bool isCrit,
    required double radius,
    double damageScale = 1.0,
    required bool allowCrit,
  }) {
    final dir = (target.position - context.position);
    if (dir.length2 <= 0.0001) return;

    final effectiveRadius = radius + reachBonus;
    if (effectiveRadius > 0 && dir.length2 > effectiveRadius * effectiveRadius) return;

    final finalDamage = (baseDamage * damageScale).round().clamp(1, 999999);
    final finalCrit = allowCrit ? isCrit : false;

    _applyMeleeHit(
      context,
      target: target,
      damage: finalDamage,
      isCrit: finalCrit,
      slashColor: slashColor,
      slashLength: 40,
      slashThickness: 5,
      slashMaxAlpha: 0.75,
    );
  }
}

void _applyMeleeHit(
  PlayerAttackContext context, {
  required EnemyComponent target,
  required int damage,
  required bool isCrit,
  required Color slashColor,
  required double slashLength,
  required double slashThickness,
  required double slashMaxAlpha,
}) {
  target.takeDamageFromHit(
    damage,
    isCrit: isCrit,
    attacker: context.owner,
    sourceType: DamageSourceType.melee,
  );
  context.buffs.emit(
    DamageDealtEvent(
      attacker: context.owner,
      target: target,
      amount: damage,
      isCrit: isCrit,
      sourceType: DamageSourceType.melee,
    ),
  );

  final dir = (target.position - context.position);
  final dirNorm = dir.normalized();
  final slashPos = target.position - dirNorm * 6;
  final slashAngle = atan2(dirNorm.y, dirNorm.x);
  context.addWorldComponent(
    MeleeSlashEffect(
      position: slashPos,
      angle: slashAngle,
      length: slashLength,
      thickness: slashThickness,
      color: slashColor,
      maxAlpha: slashMaxAlpha,
      lifeSeconds: 0.12,
    ),
  );
}
