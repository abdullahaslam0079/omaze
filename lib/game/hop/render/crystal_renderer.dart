import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/render/render_context.dart';

/// Draws a glowing crystal nestled in the meadow.
class CrystalRenderer {
  const CrystalRenderer._();

  static void draw(Canvas canvas, int lane, int z, HopRenderContext ctx) {
    final seed = lane * 13 + z * 21;
    final sc = 0.9 + (seed % 6) * 0.035;
    final p = ctx.tilePos(lane + 0.6, z + 0.4);
    final pulse = 0.55 + 0.45 * ((math.sin(ctx.time * 2.2 + lane) + 1) / 2);

    canvas.drawOval(
      Rect.fromCenter(center: p + Offset(0, 4 * sc), width: 14 * sc, height: 5 * sc),
      Paint()..color = const Color(0x28000000),
    );

    ctx.glow(canvas, p + Offset(0, -6 * sc), 14 * sc, Color.fromRGBO(130, 220, 255, 0.2 * pulse));

    _shard(canvas, p + Offset(-5 * sc, 0), 0.62 * sc, -0.18);
    _shard(canvas, p + Offset(5.5 * sc, 1 * sc), 0.55 * sc, 0.22);
    _shard(canvas, p, sc, 0);

    canvas.drawLine(
      p + Offset(-2 * sc, -11 * sc),
      p + Offset(1.2 * sc, -2 * sc),
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.55 + 0.25 * pulse)
        ..strokeWidth = 1.2 * sc
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _shard(Canvas canvas, Offset p, double sc, double tilt) {
    final gem = Path()
      ..moveTo(p.dx + tilt * 8, p.dy - 16 * sc)
      ..lineTo(p.dx + 7 * sc + tilt * 4, p.dy - 4 * sc)
      ..lineTo(p.dx + tilt * 2, p.dy + 4 * sc)
      ..lineTo(p.dx - 7 * sc + tilt * 4, p.dy - 4 * sc)
      ..close();
    canvas.drawPath(gem, Paint()..color = const Color(0xFF6AC8E8));
    canvas.drawPath(
      Path()
        ..moveTo(p.dx + tilt * 8, p.dy - 16 * sc)
        ..lineTo(p.dx + 7 * sc + tilt * 4, p.dy - 4 * sc)
        ..lineTo(p.dx + 1 * sc + tilt * 4, p.dy - 5 * sc)
        ..close(),
      Paint()..color = const Color(0x55E8FFFF),
    );
    canvas.drawPath(
      gem,
      Paint()
        ..color = const Color(0xAAE8FFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }
}
