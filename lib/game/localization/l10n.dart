import 'package:flutter/foundation.dart';
import 'package:pixel_clash/game/localization/app_locale.dart';

class L10n {
  L10n({AppLocale initial = AppLocale.ru}) : locale = ValueNotifier(initial);

  final ValueNotifier<AppLocale> locale;

  /// Базовая строка.
  /// Если ключа нет — показываем сам ключ (чтобы быстро заметить).
  String t(String key) {
    final map = _strings[locale.value] ?? const <String, String>{};
    return map[key] ?? '[$key]';
  }

  /// Строка с подстановками вида "{value}".
  /// Если в строке нет плейсхолдеров — вернёт как есть.
  String tParams(String key, Map<String, String> params) {
    var s = t(key);
    params.forEach((k, v) {
      s = s.replaceAll('{$k}', v);
    });
    return s;
  }

  void setLocale(AppLocale value) => locale.value = value;

  static const Map<AppLocale, Map<String, String>> _strings = {
    AppLocale.ru: {
      // Общие
      'game_title': 'PIXEL CLASH',
      'choose_hero': 'Выбор героя',
      'choose_upgrade': 'Выбор улучшения',
      'tap_one_of_three': 'Выбери 1 из 3',

      // Герои
      'hero_ranger_title': 'Рейнджер (лук)',
      'hero_ranger_subtitle': 'Дальний бой, кайтинг',
      'hero_knight_title': 'Рыцарь (меч/щит)',
      'hero_knight_subtitle': 'Выживание, ближний бой',

      // HUD
      'hud_timer': 'Таймер',
      'hud_score': 'Score',
      'hud_threat': 'Threat',
      'hud_keys': 'Ключи',
      'hud_keys_todo': '(позже добавим)',
      'hud_threat_multiplier': '(множитель растёт)',
      'hud_armor': 'Броня',

      // Апгрейды (lvlUp)
      'upg_damage_title': '+ Урон',
      'upg_damage_desc': 'Увеличивает урон героя на +{value}.',

      'upg_as_title': '+ Скорость атаки',
      'upg_as_desc': 'Атакуешь чаще: +{value} атак/сек.',

      'upg_armor_title': '+ Броня',
      'upg_armor_desc': 'Снижается входящий урон: +{value} брони.',

      'upg_hp_title': '+ HP',
      'upg_hp_desc': 'Увеличивает максимум HP на +{value} и лечит на это значение.',

      'upg_crit_title': '+ Шанс крита',
      'upg_crit_desc': 'Шанс критического удара +{value}%.',

      'upg_ms_title': '+ Скорость',
      'upg_ms_desc': 'Скорость перемещения +{value}.',

      'upg_vamp_title': 'Вампиризм',
      'upg_vamp_desc': 'Лечит на {value}% от нанесённого урона.',

      // Алтари / бафы
      'altar_freeze_title': 'Ледяной холод',
      'altar_freeze_desc': 'Пока заглушка: в будущем атаки смогут замедлять врагов.',

      'altar_chain_lightning_title': 'Цепная молния',
      'altar_chain_lightning_desc':
          'Каждый удар имеет шанс выпустить молнию: она перепрыгивает по ближайшим врагам и наносит часть урона.',

      'altar_thorns_title': 'Шипы',
      'altar_thorns_desc':
          'Пока заглушка: в будущем часть урона будет отражаться обратно во врага.',

      'chest_book_hardship_title': 'Книга испытаний',
      'chest_book_hardship_desc': 'В твоём ране враги появляются чаще: +{value}%.',
      'altar_vamp_title': 'Вампиризм',
      'altar_vamp_desc': 'Каждый удар лечит тебя на {value}% от нанесённого урона.',
    },
    AppLocale.en: {
      'game_title': 'PIXEL CLASH',
      'choose_hero': 'Choose Hero',
      'choose_upgrade': 'Choose Upgrade',
      'tap_one_of_three': 'Pick 1 of 3',
      'hero_ranger_title': 'Ranger (Bow)',
      'hero_ranger_subtitle': 'Ranged, kiting',
      'hero_knight_title': 'Knight (Sword/Shield)',
      'hero_knight_subtitle': 'Survival, melee',
      'hud_timer': 'Timer',
      'hud_score': 'Score',
      'hud_threat': 'Threat',
      'hud_keys': 'Keys',
      'hud_keys_todo': '(later)',
      'hud_threat_multiplier': '(multiplier grows)',
      'hud_armor': 'Armor',
      'upg_damage_title': '+ Damage',
      'upg_damage_desc': 'Increases your damage by +{value}.',
      'upg_as_title': '+ Attack speed',
      'upg_as_desc': 'Attack more often: +{value} attacks/sec.',
      'upg_armor_title': '+ Armor',
      'upg_armor_desc': 'Reduces incoming damage: +{value} armor.',
      'upg_hp_title': '+ HP',
      'upg_hp_desc': 'Increases max HP by +{value} and heals for that amount.',
      'upg_crit_title': '+ Crit chance',
      'upg_crit_desc': 'Critical hit chance +{value}%.',
      'upg_ms_title': '+ Move speed',
      'upg_ms_desc': 'Movement speed +{value}.',
      'upg_vamp_title': 'Vampirism',
      'upg_vamp_desc': 'Heals for {value}% of damage dealt.',
      'altar_freeze_title': 'Icy Chill',
      'altar_freeze_desc': 'Stub for now: later your attacks will be able to slow enemies.',
      'altar_chain_lightning_title': 'Chain Lightning',
      'altar_chain_lightning_desc':
          'Each hit has a chance to release lightning: it jumps to nearby enemies and deals a fraction of your damage.',
      'altar_thorns_title': 'Thorns',
      'altar_thorns_desc': 'Stub for now: later a portion of damage will be reflected back.',
      'chest_book_hardship_title': 'Book of Hardship',
      'chest_book_hardship_desc': 'In your run enemies spawn more often: +{value}%.',
      'altar_vamp_title': 'Vampirism',
      'altar_vamp_desc': 'Each hit heals you for {value}% of damage dealt.',
    },
  };
}
