import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/domain/domain.dart';
import 'package:omaze/game/hop/render/render_context.dart';

/// Draws collectible gem coins.
class CoinRenderer {
  const CoinRenderer._();

  static void drawAll(Canvas canvas, List<Coin> coins, HopRenderContext ctx) {
    for (final coin in coins) {
      if (coin.taken && coin.pop >= 1) continue;
      final p = ctx.tilePos(coin.lane + 0.5, coin.z + 0.4);
      final bob = math.sin(ctx.time * 5 + coin.lane) * 3;
      final s = coin.taken ? 1 + coin.pop * 0.8 : 1.0;
      final a = coin.taken ? 1 - coin.pop : 1.0;
      canvas.save();
      canvas.translate(p.dx, p.dy - 12 - bob - coin.pop * 18);
      canvas.scale(s, s);
      canvas.drawOval(
        const Rect.fromLTWH(-8, 12, 16, 5),
        Paint()..color = Color.fromRGBO(0, 0, 0, 0.22 * a),
      );
      ctx.glow(canvas, Offset.zero, 12, Color.fromRGBO(232, 195, 106, 0.35 * a));
      final gem = Path()
        ..moveTo(0, -10)
        ..lineTo(8, -2)
        ..lineTo(0, 8)
        ..lineTo(-8, -2)
        ..close();
      canvas.drawPath(gem, Paint()..color = Color.fromRGBO(232, 195, 106, a));
      canvas.drawPath(
        gem,
        Paint()
          ..color = Color.fromRGBO(255, 244, 200, a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawLine(
        const Offset(-2, -6),
        const Offset(1, 0),
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, 0.8 * a)
          ..strokeWidth = 1.1,
      );
      canvas.restore();
    }
  }
}
