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
  });

  final RewardDefinition reward;
  final VoidCallback onPick;

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
          child: Row(
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
                    Text(
                      reward.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _RarityChip(rarity: reward.rarity),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onPick,
                style: ElevatedButton.styleFrom(
                  backgroundColor: borderColor.withValues(alpha: 0.22),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
                  ),
                ),
                child: const Text('Взять'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        ),
      ),
    );
  }
}
