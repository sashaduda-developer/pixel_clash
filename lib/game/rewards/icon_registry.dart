import 'package:flutter/material.dart';

class IconRegistry {
  const IconRegistry();

  IconData iconByKey(String key) {
    return switch (key) {
      'bolt' => Icons.bolt,
      'snow' => Icons.ac_unit,
      'shield' => Icons.shield,
      'stat' => Icons.trending_up,
      _ => Icons.auto_awesome,
    };
  }
}
