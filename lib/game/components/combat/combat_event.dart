import 'package:flame/components.dart';

/// Тип источника события (откуда пришло).
enum DamageSourceType {
  arrow,
  melee,
  thorn,
  ability,
  unknown,
}

/// Базовый интерфейс события боя.
sealed class CombatEvent {
  const CombatEvent();
}

/// Игрок нанёс урон врагу.
class DamageDealtEvent extends CombatEvent {
  const DamageDealtEvent({
    required this.attacker,
    required this.target,
    required this.amount,
    required this.isCrit,
    required this.sourceType,
  });

  /// Кто нанёс урон (обычно PlayerComponent).
  final PositionComponent attacker;

  /// Кому нанесли урон (обычно EnemyComponent).
  final PositionComponent target;

  /// Сколько урона прошло (уже финальный).
  final int amount;

  /// Был ли это крит.
  final bool isCrit;

  /// Тип источника (стрела/мили/способность/и т.д.).
  final DamageSourceType sourceType;
}

/// Игрок получил урон.
class DamageTakenEvent extends CombatEvent {
  const DamageTakenEvent({
    required this.victim,
    this.attacker,
    required this.amount,
    required this.sourceType,
  });

  final PositionComponent victim;
  final PositionComponent? attacker;

  final int amount;
  final DamageSourceType sourceType;
}

/// Враг умер.
class EnemyKilledEvent extends CombatEvent {
  const EnemyKilledEvent({
    required this.killer,
    required this.enemy,
  });

  final PositionComponent killer;
  final PositionComponent enemy;
}
