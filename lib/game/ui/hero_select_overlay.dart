import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/player/hero_type.dart';
import 'package:pixel_clash/game/localization/l10n.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/ui/overlays.dart';

class HeroSelectOverlay extends StatelessWidget {
  const HeroSelectOverlay({super.key, required this.game});

  final PixelClashGame game;

  @override
  Widget build(BuildContext context) {
    final L10n l10n = game.l10n;

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
                  _HeroButton(
                    title: l10n.t('hero_ranger_title'),
                    subtitle: l10n.t('hero_ranger_subtitle'),
                    onTap: () async => _start(HeroType.ranger),
                  ),
                  const SizedBox(height: 10),
                  _HeroButton(
                    title: l10n.t('hero_knight_title'),
                    subtitle: l10n.t('hero_knight_subtitle'),
                    onTap: () async => _start(HeroType.knight),
                  ),
                  const SizedBox(height: 10),
                  _HeroButton(
                    title: l10n.t('hero_mage_title'),
                    subtitle: l10n.t('hero_mage_subtitle'),
                    onTap: () async => _start(HeroType.mage),
                  ),
                  const SizedBox(height: 10),
                  _HeroButton(
                    title: l10n.t('hero_ninja_title'),
                    subtitle: l10n.t('hero_ninja_subtitle'),
                    onTap: () async => _start(HeroType.ninja),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _start(HeroType type) async {
    game.overlays.remove(Overlays.heroSelect);
    await game.startGame(type);

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
