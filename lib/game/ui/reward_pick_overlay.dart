import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/rarity.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/rewards/reward_definition.dart';

/// Оверлей выбора награды (вертикальные карточки).
class RewardPickOverlay extends StatelessWidget {
  const RewardPickOverlay({super.key, required this.game});

  final PixelClashGame game;

  @override
  Widget build(BuildContext context) {
    // choices лежат в game.rewardChoices
    return ValueListenableBuilder<List<RewardDefinition>>(
      valueListenable: game.rewardChoices,
      builder: (context, choices, _) {
        // Блокируем клики по игре: полноэкранный overlay.
        return Material(
          color: Colors.black.withValues(alpha: 0.65),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Выбор награды',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...choices.map((r) => _RewardCard(
                          reward: r,
                          onPick: () {
                            game.applyRewardAndResume(r);
                          },
                          onSkip: r.source == RewardSource.chest
                              ? () {
                                  game.skipRewardAndResume();
                                }
                              : null,
                        )),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        // На будущее: реролл, но сейчас просто закрыть нельзя.
                      },
                      child: const Text(
                        ' ',
                        style: TextStyle(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.onPick,
    this.onSkip,
  });

  final RewardDefinition reward;
  final VoidCallback onPick;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final borderColor = _rarityBorder(reward.rarity);
    final bg = Colors.white.withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 6),
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      reward.icon,
                      color: borderColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              reward.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            _RarityChip(rarity: reward.rarity),
                            if (reward.kind == RewardKind.ability || reward.kind == RewardKind.buff)
                              _KindChip(kind: reward.kind),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reward.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.2,
                          ),
                        ),
                        if (reward.stats != null && reward.stats!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _StatChips(values: reward.stats!, color: borderColor),
                        ],
                        if (onSkip != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: onSkip,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: BorderSide(color: borderColor.withValues(alpha: 0.4)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text('Уйти'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: onPick,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: borderColor.withValues(alpha: 0.22),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                  child: const Text('Взять'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (reward.maxLevel != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _LevelText(
                    current: reward.currentLevel ?? 0,
                    max: reward.maxLevel ?? 1,
                    color: borderColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _rarityBorder(Rarity r) {
    return switch (r) {
      Rarity.common => const Color(0xFFB0BEC5),
      Rarity.rare => const Color(0xFF64B5F6),
      Rarity.epic => const Color(0xFFBA68C8),
      Rarity.legendary => const Color(0xFFFFD54F),
    };
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({required this.rarity});

  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (rarity) {
      Rarity.common => ('Обычное', const Color(0xFFB0BEC5)),
      Rarity.rare => ('Редкое', const Color(0xFF64B5F6)),
      Rarity.epic => ('Эпическое', const Color(0xFFBA68C8)),
      Rarity.legendary => ('Легендарное', const Color(0xFFFFD54F)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind});

  final RewardKind kind;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (kind) {
      RewardKind.ability => ('Активная', const Color(0xFF4FC3F7)),
      RewardKind.buff => ('Пассивная', const Color(0xFF81C784)),
      _ => ('', const Color(0xFFB0BEC5)),
    };

    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatChips extends StatelessWidget {
  const _StatChips({required this.values, required this.color});

  final List<RewardStat> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Строки характеристик показываем отдельными чипами.
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values.map((stat) {
        final chipColor = _chipColor(stat);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: chipColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            '${stat.label} ${stat.value}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _chipColor(RewardStat stat) {
    return switch (stat.polarity) {
      RewardStatPolarity.positive => const Color(0xFF81C784),
      RewardStatPolarity.negative => const Color(0xFFE57373),
      RewardStatPolarity.neutral => color,
    };
  }
}

class _LevelText extends StatelessWidget {
  const _LevelText({
    required this.current,
    required this.max,
    required this.color,
  });

  final int current;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$current/$max',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
