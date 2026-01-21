import 'package:flame/components.dart';
import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/combat/combat_event.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Система бафов игрока.
/// Хранит список бафов и прокидывает им события.
class BuffSystem {
  BuffSystem(this.owner);

  final PlayerComponent owner;

  final List<Buff> _buffs = <Buff>[];

  List<Buff> get buffs => List<Buff>.unmodifiable(_buffs);

  /// Возвращает бафф по id, если есть.
  Buff? getBuff(String id) {
    for (final b in _buffs) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Возвращает бафф конкретного типа, если он совпадает.
  T? getBuffAs<T extends Buff>(String id) {
    final b = getBuff(id);
    if (b is T) return b;
    return null;
  }

  /// Добавить баф.
  ///
  /// Если баф уже есть:
  /// - если стакуемый: увеличим стаки/уровень (как решит баф)
  /// - если не стакуемый: игнор
  void addBuff(Buff buff) {
    final existingIndex = _buffs.indexWhere((b) => b.id == buff.id);
    if (existingIndex == -1) {
      _buffs.add(buff);
      return;
    }

    final existing = _buffs[existingIndex];
    if (!existing.isStackable) return;

    // Самая простая логика: +1 уровень и +1 стак.
    // Потом можно вынести в конкретный баф.
    existing.level += 1;
    existing.stacks += 1;
  }

  bool hasBuff(String id) => _buffs.any((b) => b.id == id);

  /// Отправить событие всем бафам.
  void emit(CombatEvent event) {
    // Копию списка берём на случай, если баф добавит/удалит бафы внутри onEvent.
    final snapshot = List<Buff>.from(_buffs);
    for (final b in snapshot) {
      b.onEvent(owner, event);
    }
  }

  /// Позволяет бафам менять входящий урон (например, блок/щит).
  int modifyIncomingDamage(
    int damage, {
    required DamageSourceType sourceType,
    required PositionComponent? attacker,
  }) {
    var result = damage;
    final snapshot = List<Buff>.from(_buffs);
    for (final b in snapshot) {
      if (b is IncomingDamageModifier) {
        result = (b as IncomingDamageModifier)
            .modifyIncomingDamage(owner, result, sourceType, attacker);
      }
    }
    return result.clamp(0, 999999);
  }
  /// Апдейт баффов по времени (ауры/кулдауны/активки).
  void update(double dt) {
    final snapshot = List<Buff>.from(_buffs);
    for (final b in snapshot) {
      b.onUpdate(owner, dt);
    }
  }
}
