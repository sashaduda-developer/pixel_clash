import 'package:flutter/material.dart';
import 'package:pixel_clash/game/localization/l10n.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final PixelClashGame game;

  @override
  Widget build(BuildContext context) {
    final L10n l10n = game.l10n;

    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: game.playerHp,
                        builder: (_, hp, __) {
                          final maxHp = game.playerMaxHp.value;
                          final ratio = (maxHp <= 0) ? 0.0 : (hp / maxHp).clamp(0.0, 1.0);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('HP: $hp/$maxHp'),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 180,
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  backgroundColor: Colors.white12,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.redAccent,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ValueListenableBuilder<double>(
                                valueListenable: game.playerMana,
                                builder: (_, mana, __) {
                                  final maxMana = game.playerMaxMana.value;
                                  final mRatio =
                                      (maxMana <= 0) ? 0.0 : (mana / maxMana).clamp(0.0, 1.0);

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${l10n.t("hud_mana")}: ${mana.toStringAsFixed(0)}/${maxMana.toStringAsFixed(0)}',
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 180,
                                        child: LinearProgressIndicator(
                                          value: mRatio,
                                          backgroundColor: Colors.white12,
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            Colors.lightBlueAccent,
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              ValueListenableBuilder<int>(
                                valueListenable: game.playerArmor,
                                builder: (_, armor, __) => Text('${l10n.t("hud_armor")}: $armor'),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        },
                      ),
                      ValueListenableBuilder<double>(
                        valueListenable: game.timeLeft,
                        builder: (_, v, __) =>
                            Text('${l10n.t('hud_timer')}: ${v.toStringAsFixed(0)}'),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: game.score,
                        builder: (_, v, __) => Text('${l10n.t('hud_score')}: $v'),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: game.threatLevel,
                        builder: (_, v, __) => Text(
                          '${l10n.t('hud_threat')}: $v ${l10n.t('hud_threat_multiplier')}',
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: game.keysFound,
                        builder: (_, v, __) =>
                            Text('${l10n.t('hud_keys')}: $v/3 ${l10n.t('hud_keys_todo')}'),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<int>(
                        valueListenable: game.level,
                        builder: (_, v, __) => Text('Lv: $v'),
                      ),
                      ValueListenableBuilder<double>(
                        valueListenable: game.xpProgress,
                        builder: (_, v, __) => SizedBox(
                          width: 180,
                          child: LinearProgressIndicator(
                            value: v,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: game.announcementText,
                    builder: (_, text, __) {
                      if (text.isEmpty) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orangeAccent),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              color: Colors.orangeAccent.withValues(alpha: 0.25),
                            ),
                          ],
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: game.bossMaxHp,
                    builder: (_, maxHp, __) {
                      if (maxHp <= 0) return const SizedBox.shrink();

                      return ValueListenableBuilder<int>(
                        valueListenable: game.bossHp,
                        builder: (_, hp, __) {
                          final ratio = (hp / maxHp).clamp(0.0, 1.0);
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ValueListenableBuilder<String>(
                                  valueListenable: game.bossName,
                                  builder: (_, name, __) => Text(
                                    name.isEmpty ? 'Boss' : name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 260,
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    backgroundColor: Colors.white12,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.deepPurpleAccent,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(top: 12, right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ],
                ),
                child: ValueListenableBuilder<double>(
                  valueListenable: game.timeLeft,
                  builder: (_, v, __) => Text(
                    _formatTime(v),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    final total = seconds.clamp(0, 99999).ceil();
    final m = total ~/ 60;
    final s = total % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
