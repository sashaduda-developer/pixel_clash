import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

/// Источник награды (важно для разных таблиц и баланса).
enum RewardSource {
  levelUp,
  chest,
  altar,
  vendor,
}

/// Тип награды.
enum RewardKind {
  buff,
  ability,
  item,
  stat,
}

/// Универсальная награда, из которой строится карточка.
/// apply() применяет награду в игру (добавить баф, изменить статы, дать валюту и т.п.)
class RewardDefinition {
  RewardDefinition({
    required this.id,
    required this.source,
    required this.kind,
    required this.rarity,
    required this.title,
    required this.description,
    required this.icon,
    required this.apply,
  });

  final String id;
  final RewardSource source;
  final RewardKind kind;
  final Rarity rarity;

  /// Пока просто строки (позже можно заменить на l10n key).
  final String title;
  final String description;

  /// Иконка карточки (позже заменим на sprite/asset).
  final IconData icon;

  final void Function(PixelClashGame game) apply;
}
