import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Базовый интерфейс пассивного эффекта (бафа/перка).
///
/// Баф НЕ хранится в stats.
/// Он подписывается на события и делает свою магию.
abstract class Buff {
  Buff({
    required this.id,
    required this.rarity,
    this.level = 1,
    this.stacks = 1,
  });

  /// Уникальный ID бафа (для сохранений/синхронизации/магазина).
  final String id;

  /// Редкость.
  final Rarity rarity;

  /// Уровень бафа (можно повышать).
  int level;

  /// Стаки (если нужно).
  int stacks;

  /// Можно ли взять этот баф повторно.
  bool get isStackable => true;

  /// События, на которые реагирует баф.
  void onEvent(PlayerComponent owner, CombatEvent event);

  /// Апдейт баффа по времени (таймеры/ауры/активные способности).
  void onUpdate(PlayerComponent owner, double dt) {}
}
