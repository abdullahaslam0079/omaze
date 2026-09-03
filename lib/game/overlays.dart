import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:omaze/game/hop_game.dart';

class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final HopGame game;

  @override
  Widget build(BuildContext context) {
    return _Shade(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: const Color(0xCC16102E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xCCE8C36A), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x55F4C542), blurRadius: 22),
                BoxShadow(color: Color(0x6614102E), blurRadius: 18, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'HOP',
                  style: TextStyle(
                    color: Color(0xFFF8E8C4),
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 12,
                    height: 1,
                    shadows: [
                      Shadow(color: Color(0xAAF4C542), blurRadius: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CROSS THE ENCHANTED LANDS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFE8C36A).withValues(alpha: 0.92),
                    fontSize: 11,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'TAP OR SWIPE TO MOVE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (game.best > 0) ...[
                  const SizedBox(height: 14),
                  Text(
                    'BEST  ${game.best}',
                    style: TextStyle(
                      color: const Color(0xFFF4C542).withValues(alpha: 0.95),
                      fontSize: 14,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(flex: 2),
          _ActionButton(
            key: const Key('play'),
            label: 'PLAY',
            onTap: () {
              HapticFeedback.selectionClick();
              game.start();
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class OverOverlay extends StatelessWidget {
  const OverOverlay({super.key, required this.game});

  final HopGame game;

  @override
  Widget build(BuildContext context) {
    return _Shade(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            decoration: BoxDecoration(
              color: const Color(0xCC16102E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xCCE8C36A), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x55F4C542), blurRadius: 22),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${game.score}',
                  style: const TextStyle(
                    color: Color(0xFFF8E8C4),
                    fontSize: 70,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    shadows: [
                      Shadow(color: Color(0xAAF4C542), blurRadius: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  game.score >= game.best && game.score > 0 ? 'NEW BEST' : 'BEST  ${game.best}',
                  style: TextStyle(
                    color: game.score >= game.best && game.score > 0
                        ? const Color(0xFFF4C542)
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (game.loot > 0 || game.bestCombo > 1) ...[
                  const SizedBox(height: 10),
                  Text(
                    [
                      if (game.loot > 0) '${game.loot} GEMS',
                      if (game.bestCombo > 1) 'COMBO ${game.bestCombo}',
                    ].join('   ·   '),
                    style: TextStyle(
                      color: const Color(0xFFE8C36A).withValues(alpha: 0.9),
                      fontSize: 12,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(flex: 2),
          _ActionButton(
            key: const Key('again'),
            label: 'AGAIN',
            onTap: () {
              HapticFeedback.selectionClick();
              game.start();
            },
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              game.showMenu();
            },
            child: Text(
              'MENU',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Shade extends StatelessWidget {
  const _Shade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0x9914102E),
              const Color(0x22000000),
              const Color(0x881A1440),
            ],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF6E0), Color(0xFFE8C36A)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF8E8C4), width: 1.4),
          boxShadow: const [
            BoxShadow(color: Color(0x88F4C542), blurRadius: 18),
            BoxShadow(color: Color(0x661A1440), blurRadius: 0, offset: Offset(0, 4)),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1440),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
          ),
        ),
      ),
    );
  }
}
