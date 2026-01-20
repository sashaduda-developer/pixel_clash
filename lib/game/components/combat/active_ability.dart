import 'package:pixel_clash/game/components/combat/buff.dart';
import 'package:pixel_clash/game/components/player/player_component.dart';

/// Интерфейс для активных способностей (ручной каст через UI).
abstract class ActiveAbility implements Buff {
  double get cooldownLeft;
  double get cooldownDuration;
  double get manaCost;

  /// Пытается активировать способность. Возвращает true при успехе.
  bool tryActivate(PlayerComponent owner);
}
