import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/render/render_context.dart';

/// Irregular mossy stones with clustered pebbles.
class RockRenderer {
  const RockRenderer._();

  static void draw(Canvas canvas, int lane, int z, HopRenderContext ctx) {
    final seed = lane * 11 + z * 29;
    final sc = 0.9 + (seed % 7) * 0.04;
    final p = ctx.tilePos(lane + 0.58 + (seed % 4) * 0.03, z + 0.44);

    canvas.drawOval(
      Rect.fromCenter(center: p + Offset(1, 5 * sc), width: 22 * sc, height: 8 * sc),
      Paint()..color = const Color(0x30000000),
    );

    _stone(canvas, p, 16 * sc, 11 * sc, seed, const Color(0xFF6E727C), const Color(0xFF9AA0AA));

    if (seed % 3 != 0) {
      _stone(
        canvas,
        p + Offset(-8 * sc, 2 * sc),
        9 * sc,
        7 * sc,
        seed + 4,
        const Color(0xFF5A5E68),
        const Color(0xFF888E98),
      );
    }
    if (seed % 2 == 0) {
      _stone(
        canvas,
        p + Offset(7 * sc, 3 * sc),
        8 * sc,
        6 * sc,
        seed + 9,
        const Color(0xFF7A7E86),
        const Color(0xFFA8AEB6),
      );
    }

    // Moss cap on the main stone.
    canvas.drawOval(
      Rect.fromCenter(center: p + Offset(-2 * sc, -3.5 * sc), width: 9 * sc, height: 4.2 * sc),
      Paint()..color = const Color(0xAA3C8A48),
    );
    canvas.drawOval(
      Rect.fromCenter(center: p + Offset(3 * sc, -2.4 * sc), width: 5 * sc, height: 2.6 * sc),
      Paint()..color = const Color(0x8858A858),
    );
  }

  static void _stone(
    Canvas canvas,
    Offset c,
    double w,
    double h,
    int seed,
    Color body,
    Color lite,
  ) {
    final path = Path();
    const n = 7;
    for (var i = 0; i < n; i++) {
      final a = i / n * math.pi * 2 - 0.4;
      final r = 0.72 + ((seed + i * 19) % 6) * 0.05;
      final x = c.dx + math.cos(a) * w * 0.5 * r;
      final y = c.dy + math.sin(a) * h * 0.5 * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = body);

    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-w * 0.16, -h * 0.18), width: w * 0.42, height: h * 0.28),
      Paint()..color = lite.withValues(alpha: 0.55),
    );
  }
}
