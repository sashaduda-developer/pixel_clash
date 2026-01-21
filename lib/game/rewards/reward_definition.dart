import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

/// Источник награды (важно для разных таблиц и баланса).
enum RewardSource {
  levelUp,
  chest,
  altar,
  boss,
  vendor,
}

/// Тип награды.
enum RewardKind {
  buff,
  ability,
  item,
  stat,
}

enum RewardStatPolarity {
  positive,
  negative,
  neutral,
}

class RewardStat {
  RewardStat({
    required this.label,
    required this.value,
    required this.polarity,
  });

  final String label;
  final String value;
  final RewardStatPolarity polarity;
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
    this.stats,
    this.currentLevel,
    this.nextLevel,
    this.maxLevel,
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

  /// Набор характеристик для отображения отдельным блоком.
  final List<RewardStat>? stats;

  /// Уровни для карточек с прогрессом (алтарные бафы/абилки).
  final int? currentLevel;
  final int? nextLevel;
  final int? maxLevel;

  final void Function(PixelClashGame game) apply;
}
