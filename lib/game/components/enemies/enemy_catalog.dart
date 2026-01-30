import 'dart:math';

import 'package:pixel_clash/game/components/enemies/enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/armored_skeleton_enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/brute_enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/greatsword_skeleton_enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/orc_enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/skeleton_enemy_factory.dart';
import 'package:pixel_clash/game/components/enemies/types/wraith_enemy_factory.dart';

class EnemyCatalog {
  EnemyCatalog._();

  static final Map<String, EnemyFactory> _factories = <String, EnemyFactory>{
    'orc': OrcEnemyFactory(),
    'wraith': WraithEnemyFactory(),
    'brute': BruteEnemyFactory(),
    'skeleton': SkeletonEnemyFactory(),
    'armored_skeleton': ArmoredSkeletonEnemyFactory(),
    'greatsword_skeleton': GreatswordSkeletonEnemyFactory(),
  };

  static EnemyFactory factoryById(String id) {
    return _factories[id] ?? _factories.values.first;
  }

  static EnemyFactory pickFactory({
    required int mapIndex,
    required double progress,
    required Random rng,
  }) {
    final pool = mapIndex == 0 ? _cemeteryPool(progress) : _defaultPool(progress);
    return _pickFromPool(pool, rng);
  }

  static List<_WeightedEnemyId> _cemeteryPool(double progress) {
    // Greatsword появляется раньше и растет быстрее, чтобы заметно встречаться в середине рана.
    final armoredWeight = ((progress - 0.08) / 0.92).clamp(0.0, 1.0) * 0.95;
    final greatswordWeight = ((progress - 0.20) / 0.80).clamp(0.0, 1.0) * 1.20;

    return <_WeightedEnemyId>[
      const _WeightedEnemyId(id: 'skeleton', weight: 1.0),
      if (armoredWeight > 0)
        _WeightedEnemyId(id: 'armored_skeleton', weight: armoredWeight),
      if (greatswordWeight > 0)
        _WeightedEnemyId(id: 'greatsword_skeleton', weight: greatswordWeight),
    ];
  }

  static List<_WeightedEnemyId> _defaultPool(double progress) {
    final wraithWeight = ((progress - 0.10) / 0.90).clamp(0.0, 1.0) * 0.90;
    final bruteWeight = ((progress - 0.45) / 0.55).clamp(0.0, 1.0) * 0.70;

    return <_WeightedEnemyId>[
      const _WeightedEnemyId(id: 'orc', weight: 1.0),
      if (wraithWeight > 0) _WeightedEnemyId(id: 'wraith', weight: wraithWeight),
      if (bruteWeight > 0) _WeightedEnemyId(id: 'brute', weight: bruteWeight),
    ];
  }

  static EnemyFactory _pickFromPool(
    List<_WeightedEnemyId> pool,
    Random rng,
  ) {
    final total = pool.fold(0.0, (sum, e) => sum + e.weight);
    var roll = rng.nextDouble() * total;
    for (final e in pool) {
      roll -= e.weight;
      if (roll <= 0) {
        return factoryById(e.id);
      }
    }
    return factoryById(pool.last.id);
  }
}

class _WeightedEnemyId {
  const _WeightedEnemyId({required this.id, required this.weight});

  final String id;
  final double weight;
}
