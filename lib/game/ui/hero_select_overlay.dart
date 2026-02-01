import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/player/hero_definition.dart';
import 'package:pixel_clash/game/localization/l10n.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/ui/overlays.dart';

class HeroSelectOverlay extends StatefulWidget {
  const HeroSelectOverlay({super.key, required this.game});

  final PixelClashGame game;

  @override
  State<HeroSelectOverlay> createState() => _HeroSelectOverlayState();
}

class _HeroSelectOverlayState extends State<HeroSelectOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  PixelClashGame get game => widget.game;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L10n l10n = game.l10n;
    final heroes = HeroCatalog.all;

    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final shift = math.sin(t * math.pi * 2) * 0.12;
              return Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-0.9, -0.9 + shift),
                          end: Alignment(0.9, 0.9 - shift),
                          colors: const [
                            Color(0xFF0E171F),
                            Color(0xFF1E2E38),
                            Color(0xFF2D2A2F),
                            Color(0xFF12161A),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _OrbGlow(
                    offset: Offset(
                      60 + 32 * math.sin(t * 5.4),
                      80 + 24 * math.cos(t * 3.1),
                    ),
                    color: const Color(0x5529D8FF),
                    size: 220,
                  ),
                  _OrbGlow(
                    offset: Offset(
                      400 + 42 * math.sin(t * 2.6 + 1.4),
                      420 + 30 * math.cos(t * 2.0 + 0.9),
                    ),
                    color: const Color(0x55FF5F6D),
                    size: 240,
                  ),
                ],
              );
            },
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DustPainter(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 900;
                final header = _HeroHeader(
                  title: l10n.t('game_title'),
                  subtitle: l10n.t('choose_hero'),
                  backLabel: l10n.t('back_to_menu'),
                  onBack: _backToMenu,
                  game: game,
                );

                final heroGrid = _HeroGrid(
                  heroes: heroes,
                  l10n: l10n,
                  onSelect: _start,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  child: isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            header,
                            const SizedBox(height: 18),
                            Expanded(child: heroGrid),
                          ],
                        )
                      : Row(
                          children: [
                            SizedBox(width: 320, child: header),
                            const SizedBox(width: 26),
                            Expanded(child: heroGrid),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _start(HeroDefinition hero) async {
    game.overlays.remove(Overlays.heroSelect);
    game.overlays.remove(Overlays.startMenu);
    await game.startGame(hero);

    if (!game.overlays.isActive(Overlays.hud)) {
      game.overlays.add(Overlays.hud);
    }
    if (!game.overlays.isActive(Overlays.abilities)) {
      game.overlays.add(Overlays.abilities);
    }
  }

  void _backToMenu() {
    game.overlays.remove(Overlays.heroSelect);
    if (!game.overlays.isActive(Overlays.startMenu)) {
      game.overlays.add(Overlays.startMenu);
    }
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.backLabel,
    required this.onBack,
    required this.game,
  });

  final String title;
  final String subtitle;
  final String backLabel;
  final VoidCallback onBack;
  final PixelClashGame game;

  @override
  Widget build(BuildContext context) {
    final L10n l10n = game.l10n;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141B22).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: Text(
              backLabel,
              style: const TextStyle(
                fontFamily: 'monospace',
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: Color(0xFFECE2CF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.t('hero_tagline'),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroGrid extends StatelessWidget {
  const _HeroGrid({
    required this.heroes,
    required this.l10n,
    required this.onSelect,
  });

  final List<HeroDefinition> heroes;
  final L10n l10n;
  final Future<void> Function(HeroDefinition) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final hero in heroes)
            _HeroCard(
              hero: hero,
              title: l10n.t(hero.titleKey),
              subtitle: l10n.t(hero.subtitleKey),
              onTap: () => onSelect(hero),
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.hero,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final HeroDefinition hero;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final base = hero.visuals.baseColor;
    final stats = hero.createStats();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onTap(),
      child: Ink(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              base.withValues(alpha: 0.22),
              const Color(0xFF1A1F26),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x77000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _HeroAvatar(hero: hero, glow: base),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.3,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'HP ${stats.maxHp} | DMG ${stats.damage} | SPD ${stats.moveSpeed.toInt()}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 0.6,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({required this.hero, required this.glow});

  final HeroDefinition hero;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    final assetPath = hero.visuals.idle.assetPath;
    final idle = hero.visuals.idle;

    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            glow.withValues(alpha: 0.55),
            const Color(0xFF111418),
          ],
        ),
      ),
      child: ClipOval(
        child: ColoredBox(
          color: const Color(0xFF0E1114),
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: idle.frameSize.width,
                height: idle.frameSize.height,
                child: SpriteAnimationWidget.asset(
                  path: assetPath,
                  data: SpriteAnimationData.sequenced(
                    amount: idle.frames,
                    stepTime: idle.stepTime,
                    textureSize: Vector2(
                      idle.frameSize.width,
                      idle.frameSize.height,
                    ),
                    loop: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbGlow extends StatelessWidget {
  const _OrbGlow({required this.offset, required this.color, required this.size});

  final Offset offset;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _DustPainter extends CustomPainter {
  _DustPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const dots = 100;
    for (var i = 0; i < dots; i++) {
      final x = (i * 83) % size.width;
      final y = (i * 59) % size.height;
      final r = (i % 3 + 1) * 0.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) => false;
}
