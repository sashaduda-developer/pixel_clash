import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/player/hero_definition.dart';
import 'package:pixel_clash/game/localization/l10n.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/ui/overlays.dart';

class HeroSelectOverlay extends StatelessWidget {
  const HeroSelectOverlay({super.key, required this.game});

  final PixelClashGame game;

  @override
  Widget build(BuildContext context) {
    final L10n l10n = game.l10n;
    final heroes = HeroCatalog.all;

    return SafeArea(
      child: Material(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${l10n.t('game_title')}\n${l10n.t('choose_hero')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < heroes.length; i++) ...[
                    _HeroButton(
                      title: l10n.t(heroes[i].titleKey),
                      subtitle: l10n.t(heroes[i].subtitleKey),
                      onTap: () async => _start(heroes[i]),
                    ),
                    if (i != heroes.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _start(HeroDefinition hero) async {
    game.overlays.remove(Overlays.heroSelect);
    await game.startGame(hero);

    if (!game.overlays.isActive(Overlays.hud)) {
      game.overlays.add(Overlays.hud);
    }
    if (!game.overlays.isActive(Overlays.abilities)) {
      game.overlays.add(Overlays.abilities);
    }
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
