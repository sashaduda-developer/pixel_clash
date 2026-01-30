import 'package:flutter/material.dart';

class IconRegistry {
  const IconRegistry();

  IconData iconByKey(String key) {
    return switch (key) {
      'bolt' => Icons.bolt,
      'snow' => Icons.ac_unit,
      'shield' => Icons.shield,
      'stat' => Icons.trending_up,
      'book' => Icons.menu_book,
      'sword' => Icons.gavel,
      'ring' => Icons.radio_button_unchecked,
      'mask' => Icons.face,
      'boots' => Icons.directions_run,
      'amulet' => Icons.star,
      'mirror' => Icons.crop_square,
      'heart' => Icons.favorite,
      _ => Icons.auto_awesome,
    };
  }
}
