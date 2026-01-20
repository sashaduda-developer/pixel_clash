import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pixel_clash/game/components/combat/active_ability.dart';
import 'package:pixel_clash/game/pixel_clash_game.dart';

class AbilitiesOverlay extends StatefulWidget {
  const AbilitiesOverlay({super.key, required this.game});

  final PixelClashGame game;

  @override
  State<AbilitiesOverlay> createState() => _AbilitiesOverlayState();
}

class _AbilitiesOverlayState extends State<AbilitiesOverlay> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 24),
          child: ValueListenableBuilder<List<String?>>(
            valueListenable: widget.game.abilitySlots,
            builder: (_, slots, __) {
              return SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: 62,
                      bottom: 112,
                      child: _AbilityButton(game: widget.game, slotIndex: 0, abilityId: slots[0]),
                    ),
                    Positioned(
                      right: 114,
                      bottom: 64,
                      child: _AbilityButton(game: widget.game, slotIndex: 1, abilityId: slots[1]),
                    ),
                    Positioned(
                      right: 14,
                      bottom: 64,
                      child: _AbilityButton(game: widget.game, slotIndex: 2, abilityId: slots[2]),
                    ),
                    Positioned(
                      right: 62,
                      bottom: 12,
                      child: _AbilityButton(game: widget.game, slotIndex: 3, abilityId: slots[3]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AbilityButton extends StatelessWidget {
  const _AbilityButton({
    required this.game,
    required this.slotIndex,
    required this.abilityId,
  });

  final PixelClashGame game;
  final int slotIndex;
  final String? abilityId;

  @override
  Widget build(BuildContext context) {
    final p = game.player;
    final ability =
        (abilityId != null && p != null) ? p.buffs.getBuffAs<ActiveAbility>(abilityId!) : null;

    final cooldownLeft = ability?.cooldownLeft ?? 0;
    final cooldownDuration = ability?.cooldownDuration ?? 0;
    final manaCost = ability?.manaCost ?? 0;
    final hasMana = p != null && manaCost <= p.stats.mana;
    final isReady = ability != null && cooldownLeft <= 0 && hasMana;

    final label = _shortLabel(abilityId) ?? 'A${slotIndex + 1}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (ability != null) ? () => game.tryActivateAbilitySlot(slotIndex) : null,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: (isReady ? const Color(0xFF1E1E1E) : const Color(0xFF141414))
                .withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: isReady ? Colors.white38 : Colors.white12),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (cooldownLeft > 0)
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cooldownLeft.ceil().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (cooldownLeft <= 0 && !hasMana && ability != null)
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: const Text(
                    'MP',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (cooldownLeft > 0 && cooldownDuration > 0)
                Positioned(
                  bottom: -18,
                  child: Text(
                    '${cooldownLeft.ceil()}s',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _shortLabel(String? id) {
    switch (id) {
      case 'ability_frost_ring':
        return 'FR';
      case 'ability_shockwave_stun':
        return 'SW';
      case 'ability_time_dilation':
        return 'TD';
    }
    return null;
  }
}
