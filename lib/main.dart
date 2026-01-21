import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'package:pixel_clash/game/pixel_clash_game.dart';
import 'package:pixel_clash/game/ui/abilities_overlay.dart';
import 'package:pixel_clash/game/ui/boss_reward_overlay.dart';
import 'package:pixel_clash/game/ui/hero_select_overlay.dart';
import 'package:pixel_clash/game/ui/hud_overlay.dart';
import 'package:pixel_clash/game/ui/overlays.dart';
import 'package:pixel_clash/game/ui/reward_pick_overlay.dart';

void main() {
  runApp(const PixelClashApp());
}

class PixelClashApp extends StatelessWidget {
  const PixelClashApp({super.key});

  @override
  Widget build(BuildContext context) {
    final game = PixelClashGame();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget<PixelClashGame>(
          game: game,
          initialActiveOverlays: const [
            Overlays.heroSelect,
          ],
          overlayBuilderMap: {
            Overlays.heroSelect: (_, g) => HeroSelectOverlay(game: g),
            Overlays.hud: (_, g) => HudOverlay(game: g),
            Overlays.abilities: (_, g) => AbilitiesOverlay(game: g),
            Overlays.rewardPick: (_, g) => RewardPickOverlay(game: g),
            Overlays.bossReward: (_, g) => BossRewardOverlay(game: g),
          },
        ),
      ),
    );
  }
}
