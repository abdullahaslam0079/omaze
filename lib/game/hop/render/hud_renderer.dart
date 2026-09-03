import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/render/render_context.dart';

/// Draws the in-game HUD (score badge, combo counter, hint text).
class HudRenderer {
  const HudRenderer._();

  static void draw(
    Canvas canvas,
    HopRenderContext ctx, {
    required int score,
    required int loot,
    required int combo,
    required int maxZ,
    required double scorePop,
    required double comboPop,
    required double hint,
  }) {
    final scale = 1 + scorePop * 0.18;
    final scoreText = TextPainter(
      text: TextSpan(
        text: '$score',
        style: const TextStyle(color: Color(0xFFF8E8C4), fontSize: 34, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final lootText = TextPainter(
      text: TextSpan(
        text: '$loot',
        style: const TextStyle(color: Color(0xFFE8C36A), fontSize: 16, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = scoreText.width + lootText.width + 64;
    final x = (ctx.size.width - w) / 2;
    canvas.save();
    canvas.translate(ctx.size.width / 2, 68);
    canvas.scale(scale, scale);
    canvas.translate(-ctx.size.width / 2, -68);
    final badge = RRect.fromRectAndRadius(Rect.fromLTWH(x, 50, w, 46), const Radius.circular(23));
    canvas.drawRRect(badge.shift(const Offset(0, 3)), Paint()..color = const Color(0x66000000));
    canvas.drawRRect(badge, Paint()..color = const Color(0xE61A1440));
    canvas.drawRRect(
      badge,
      Paint()
        ..color = const Color(0xCCE8C36A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    scoreText.paint(canvas, Offset(x + 18, 55));
    final gem = Offset(x + scoreText.width + 32, 73);
    final gemPath = Path()
      ..moveTo(gem.dx, gem.dy - 7)
      ..lineTo(gem.dx + 6, gem.dy - 1)
      ..lineTo(gem.dx, gem.dy + 6)
      ..lineTo(gem.dx - 6, gem.dy - 1)
      ..close();
    canvas.drawPath(gemPath, Paint()..color = const Color(0xFFE8C36A));
    lootText.paint(canvas, Offset(gem.dx + 10, 62));
    canvas.restore();

    if (combo >= 3) {
      final comboScale = 1 + comboPop * 0.2;
      final comboText = TextPainter(
        text: TextSpan(
          text: 'x$combo',
          style: const TextStyle(color: Color(0xFFF4C542), fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(ctx.size.width / 2, 108);
      canvas.scale(comboScale, comboScale);
      comboText.paint(canvas, Offset(-comboText.width / 2, 0));
      canvas.restore();
    }

    if (hint > 0.05 && maxZ < 3) {
      final tip = TextPainter(
        text: TextSpan(
          text: 'TAP TO HOP  ·  SIDES TO STEP  ·  SWIPE UP TO LEAP',
          style: TextStyle(
            color: Color.fromRGBO(248, 232, 196, 0.55 * hint),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tip.paint(canvas, Offset((ctx.size.width - tip.width) / 2, ctx.size.height * 0.86));
    }
  }
}
