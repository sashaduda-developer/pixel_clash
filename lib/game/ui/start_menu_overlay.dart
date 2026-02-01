import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pixel_clash/game/localization/l10n.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/ui/overlays.dart';

class StartMenuOverlay extends StatefulWidget {
  const StartMenuOverlay({super.key, required this.game});

  final PixelClashGame game;

  @override
  State<StartMenuOverlay> createState() => _StartMenuOverlayState();
}

class _StartMenuOverlayState extends State<StartMenuOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
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

    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final shift = math.sin(t * math.pi * 2) * 0.18;
              return Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1.0, -0.9 + shift),
                          end: Alignment(1.0, 1.0 - shift),
                          colors: const [
                            Color(0xFF1B1310),
                            Color(0xFF3A2318),
                            Color(0xFF5B3220),
                            Color(0xFF2B1A16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _OrbGlow(
                    offset: Offset(
                      80 + 40 * math.sin(t * 6.2),
                      120 + 28 * math.cos(t * 4.6),
                    ),
                    color: const Color(0x55FFC27A),
                    size: 180,
                  ),
                  _OrbGlow(
                    offset: Offset(
                      320 + 60 * math.sin(t * 3.4 + 1.2),
                      380 + 36 * math.cos(t * 2.2 + 0.8),
                    ),
                    color: const Color(0x5546C6FF),
                    size: 220,
                  ),
                  _OrbGlow(
                    offset: Offset(
                      520 + 50 * math.sin(t * 2.6 + 2.0),
                      160 + 24 * math.cos(t * 3.0 + 1.7),
                    ),
                    color: const Color(0x55FF6B6B),
                    size: 160,
                  ),
                ],
              );
            },
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DustPainter(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF17100E),
                        Color(0xFF2E1D16),
                        Color(0xFF1E1412),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x88000000),
                        blurRadius: 32,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.t('game_title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 36,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFDE7C2),
                          shadows: [
                            Shadow(
                              blurRadius: 16,
                              color: Color(0xAA000000),
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.t('start_tagline'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _StartButton(
                        label: l10n.t('start_game'),
                        onTap: _openHeroSelect,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.t('early_access'),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.45),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openHeroSelect() {
    if (!game.overlays.isActive(Overlays.heroSelect)) {
      game.overlays.add(Overlays.heroSelect);
    }
    game.overlays.remove(Overlays.startMenu);
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
        ],
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
    const dots = 120;
    for (var i = 0; i < dots; i++) {
      final x = (i * 97) % size.width;
      final y = (i * 53) % size.height;
      final r = (i % 3 + 1) * 0.6;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) => false;
}
