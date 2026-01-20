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
      'hero_mage_title': 'Маг (посох)',
      'hero_mage_subtitle': 'Много маны, дальние, но медленные атаки',
      'hero_ninja_title': 'Ниндзя (клинки)',
      'hero_ninja_subtitle': 'Быстрый ближний бой и уклонение',

      // HUD
      'hud_timer': 'Таймер',
      'hud_score': 'Score',
      'hud_threat': 'Threat',
      'hud_keys': 'Ключи',
      'hud_keys_todo': '(позже добавим)',
      'hud_threat_multiplier': '(множитель растёт)',
      'hud_armor': 'Броня',
      'hud_mana': 'Мана',

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
      'upg_mana_title': '+ Мана',
      'upg_mana_desc': 'Макс. мана +{value}.',
      'upg_mana_regen_title': '+ Реген маны',
      'upg_mana_regen_desc': 'Реген маны +{value}/с.',
      'upg_evasion_title': 'Уклонение',
      'upg_evasion_desc': 'Шанс избежать урона +{value}%.',

      'upg_vamp_title': 'Вампиризм',
      'upg_vamp_desc': 'Лечит на {value}% от нанесённого урона.',

      // Алтари / бафы
      'altar_freeze_title': 'Ледяной холод',
      'altar_freeze_desc': 'Пока заглушка: в будущем атаки смогут замедлять врагов.',

      // ===== ALTAR v2 (редкость = класс скилла) =====
      'altar_freeze_aura_title': 'Аура заморозки',
      'altar_freeze_aura_desc':
          'Периодически замораживает ближайших врагов вокруг тебя. Повторный выбор повышает уровень.',

      'altar_ignite_title': 'Поджог',
      'altar_ignite_desc': 'Иногда удар поджигает цель, нанося урон со временем.',

      'altar_slow_strikes_title': 'Ледяные удары',
      'altar_slow_strikes_desc': 'Каждый удар замедляет врага на короткое время.',

      'altar_thorns_desc_v2': 'Часть полученного урона отражается обратно во врага.',

      'altar_piercing_title': 'Пробитие',
      'altar_piercing_desc': 'Снаряды проходят сквозь врагов и летят дальше.',

      'altar_ricochet_title': 'Рикошет',
      'altar_ricochet_desc': 'Снаряды могут отскакивать в другую цель.',

      'altar_bleed_title': 'Кровотечение',
      'altar_bleed_desc': 'Иногда удар вызывает кровотечение, нанося урон со временем.',

      'altar_soul_on_kill_title': 'Сферы душ',
      'altar_soul_on_kill_desc': 'Убийства иногда создают сферу, которая летит к тебе и лечит.',

      'altar_nova_burst_title': 'Нова',
      'altar_nova_burst_desc':
          'Иногда удар вызывает взрыв вокруг цели и задевает ближайших врагов.',

      'altar_poison_cloud_title': 'Ядовитое облако',
      'altar_poison_cloud_desc': 'Вокруг тебя появляется облако, которое постепенно травит врагов.',

      'altar_frost_ring_title': 'Кольцо льда',
      'altar_frost_ring_desc':
          'Активная способность: ледяная волна вокруг тебя замораживает врагов.',

      'altar_shockwave_title': 'Ударная волна',
      'altar_shockwave_desc':
          'Активная способность: мощная волна вокруг тебя наносит урон и оглушает.',

      'altar_tempest_field_title': 'Поле бури',
      'altar_tempest_field_desc': 'Периодически бьёт молнией по нескольким ближайшим врагам.',

      'altar_time_dilation_title': 'Искажение времени',
      'altar_time_dilation_desc':
          'Активная способность: замедляет врагов вокруг на короткое время.',

      'altar_reaper_mark_title': 'Метка жнеца',
      'altar_reaper_mark_desc':
          'Каждое убийство даёт стак. Набери достаточно стаков — и произойдёт мощный взрыв.',

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
      'hero_mage_title': 'Mage (staff)',
      'hero_mage_subtitle': 'High mana, ranged but slower attacks',
      'hero_ninja_title': 'Ninja (blades)',
      'hero_ninja_subtitle': 'Fast melee with evasion',
      'hud_timer': 'Timer',
      'hud_score': 'Score',
      'hud_threat': 'Threat',
      'hud_keys': 'Keys',
      'hud_keys_todo': '(later)',
      'hud_threat_multiplier': '(multiplier grows)',
      'hud_armor': 'Armor',
      'hud_mana': 'Mana',
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
      'upg_mana_title': '+ Mana',
      'upg_mana_desc': 'Max mana +{value}.',
      'upg_mana_regen_title': '+ Mana regen',
      'upg_mana_regen_desc': 'Mana regen +{value}/s.',
      'upg_evasion_title': 'Evasion',
      'upg_evasion_desc': 'Chance to avoid damage +{value}%.',
      'upg_vamp_title': 'Vampirism',
      'upg_vamp_desc': 'Heals for {value}% of damage dealt.',
      'altar_freeze_title': 'Icy Chill',
      'altar_freeze_desc': 'Stub for now: later your attacks will be able to slow enemies.',

      // ===== ALTAR v2 (rarity = skill class) =====
      'altar_freeze_aura_title': 'Freeze Aura',
      'altar_freeze_aura_desc':
          'Periodically freezes nearby enemies around you. Picking it again increases its level.',

      'altar_ignite_title': 'Ignite',
      'altar_ignite_desc': 'Sometimes your hit ignites the target, dealing damage over time.',

      'altar_slow_strikes_title': 'Frost Strikes',
      'altar_slow_strikes_desc': 'Each hit slows the enemy for a short time.',

      'altar_thorns_desc_v2': 'A portion of damage taken is reflected back to the attacker.',

      'altar_piercing_title': 'Piercing',
      'altar_piercing_desc': 'Projectiles pass through enemies and fly further.',

      'altar_ricochet_title': 'Ricochet',
      'altar_ricochet_desc': 'Projectiles can bounce to another target.',

      'altar_bleed_title': 'Bleed',
      'altar_bleed_desc': 'Sometimes your hit causes bleeding, dealing damage over time.',

      'altar_soul_on_kill_title': 'Soul Orbs',
      'altar_soul_on_kill_desc': 'Kills sometimes create an orb that flies to you and heals.',

      'altar_nova_burst_title': 'Nova Burst',
      'altar_nova_burst_desc': 'Sometimes your hit triggers an explosion around the target.',

      'altar_poison_cloud_title': 'Poison Cloud',
      'altar_poison_cloud_desc': 'A cloud around you gradually poisons nearby enemies.',

      'altar_frost_ring_title': 'Frost Ring',
      'altar_frost_ring_desc': 'Active ability: an icy wave around you freezes enemies.',

      'altar_shockwave_title': 'Shockwave',
      'altar_shockwave_desc': 'Active ability: a powerful wave around you deals damage and stuns.',

      'altar_tempest_field_title': 'Tempest Field',
      'altar_tempest_field_desc': 'Periodically strikes lightning at several nearby enemies.',

      'altar_time_dilation_title': 'Time Dilation',
      'altar_time_dilation_desc': 'Active ability: slows enemies around you for a short time.',

      'altar_reaper_mark_title': 'Reaper\'s Mark',
      'altar_reaper_mark_desc':
          'Each kill gives a stack. Reach the threshold to unleash a powerful explosion.',

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
