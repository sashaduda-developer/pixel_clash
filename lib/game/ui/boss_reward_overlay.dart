import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/rewards/reward_definition.dart';

class BossRewardOverlay extends StatelessWidget {
  const BossRewardOverlay({super.key, required this.game});

  final PixelClashGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RewardDefinition?>(
      valueListenable: game.bossRewardChoice,
      builder: (_, reward, __) {
        if (reward == null) return const SizedBox.shrink();

        final borderColor = _rarityColor(reward.rarity);

        return Material(
          color: Colors.black.withValues(alpha: 0.65),
          child: Center(
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2A1C10),
                    Color(0xFF3A2410),
                    Color(0xFF2A1C10),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'НАГРАДА БОССА',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconBadge(icon: reward.icon, color: borderColor),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reward.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                _RarityBadge(rarity: reward.rarity),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              reward.description,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            if (reward.stats != null && reward.stats!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _StatChips(values: reward.stats!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 180,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: game.applyBossRewardAndResume,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB76B1A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Взять',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity});

  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _rarityColor(rarity).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _rarityColor(rarity)),
      ),
      child: Text(
        _rarityLabel(rarity),
        style: TextStyle(
          color: _rarityColor(rarity),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatChips extends StatelessWidget {
  const _StatChips({required this.values});

  final List<RewardStat> values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values.map((s) => _StatChip(stat: s)).toList(),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.stat});

  final RewardStat stat;

  @override
  Widget build(BuildContext context) {
    final color = _statColor(stat.polarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Text(
        '${stat.label} ${stat.value}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statColor(RewardStatPolarity polarity) {
  switch (polarity) {
    case RewardStatPolarity.positive:
      return const Color(0xFF6EE787);
    case RewardStatPolarity.negative:
      return const Color(0xFFFF6B6B);
    case RewardStatPolarity.neutral:
      return const Color(0xFFB0BEC5);
  }
}

Color _rarityColor(Rarity rarity) {
  switch (rarity) {
    case Rarity.common:
      return const Color(0xFFB0BEC5);
    case Rarity.rare:
      return const Color(0xFF64B5F6);
    case Rarity.epic:
      return const Color(0xFFB388FF);
    case Rarity.legendary:
      return const Color(0xFFFFB74D);
  }
}

String _rarityLabel(Rarity rarity) {
  switch (rarity) {
    case Rarity.common:
      return 'Обычное';
    case Rarity.rare:
      return 'Редкое';
    case Rarity.epic:
      return 'Эпическое';
    case Rarity.legendary:
      return 'Легендарное';
  }
}
