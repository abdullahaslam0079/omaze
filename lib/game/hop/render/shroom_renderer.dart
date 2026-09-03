import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/render/render_context.dart';

/// Layered meadow mushrooms with a light idle bounce.
class ShroomRenderer {
  const ShroomRenderer._();

  static void draw(Canvas canvas, int lane, int z, HopRenderContext ctx) {
    final seed = lane * 19 + z * 23;
    final kind = seed % 3;
    final sc = 0.86 + (seed % 8) * 0.04;
    final bounce = math.sin(ctx.time * 1.7 + lane * 0.8 + z * 0.3) * 0.7;
    final p = ctx.tilePos(lane + 0.52 + (seed % 4) * 0.03, z + 0.46);
    final base = p + Offset(0, bounce);

    canvas.drawOval(
      Rect.fromCenter(center: p + Offset(1, 9 * sc), width: 16 * sc, height: 5 * sc),
      Paint()..color = const Color(0x30000000),
    );

    // Stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base + Offset(0, 4 * sc), width: 7 * sc, height: 12 * sc),
        Radius.circular(3 * sc),
      ),
      Paint()..color = const Color(0xFFE8D8B8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base + Offset(1.6 * sc, 4 * sc), width: 2.4 * sc, height: 10 * sc),
        Radius.circular(1.2 * sc),
      ),
      Paint()..color = const Color(0x55FFFFFF),
    );

    final Color capDark;
    final Color capMid;
    final Color capLite;
    switch (kind) {
      case 0:
        capDark = const Color(0xFF9A2C2C);
        capMid = const Color(0xFFD24B4B);
        capLite = const Color(0xFFE87870);
      case 1:
        capDark = const Color(0xFF6A4A28);
        capMid = const Color(0xFFB07A48);
        capLite = const Color(0xFFD4A070);
      default:
        capDark = const Color(0xFF4A2A78);
        capMid = const Color(0xFF7A58C0);
        capLite = const Color(0xFFA888E0);
    }

    final capY = base.dy - 2 * sc;
    final cap = Path()
      ..moveTo(base.dx - 12 * sc, capY + 2 * sc)
      ..quadraticBezierTo(base.dx - 13 * sc, capY - 8 * sc, base.dx, capY - 13 * sc)
      ..quadraticBezierTo(base.dx + 13 * sc, capY - 8 * sc, base.dx + 12 * sc, capY + 2 * sc)
      ..quadraticBezierTo(base.dx, capY + 5 * sc, base.dx - 12 * sc, capY + 2 * sc)
      ..close();
    canvas.drawPath(cap, Paint()..color = capMid);

    final underside = Path()
      ..moveTo(base.dx - 11 * sc, capY + 1.5 * sc)
      ..quadraticBezierTo(base.dx, capY + 5.5 * sc, base.dx + 11 * sc, capY + 1.5 * sc)
      ..quadraticBezierTo(base.dx, capY + 1 * sc, base.dx - 11 * sc, capY + 1.5 * sc)
      ..close();
    canvas.drawPath(underside, Paint()..color = capDark);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(base.dx - 3 * sc, capY - 7 * sc), width: 10 * sc, height: 5 * sc),
      Paint()..color = capLite.withValues(alpha: 0.55),
    );

    if (kind != 1) {
      _spot(canvas, Offset(base.dx - 4 * sc, capY - 5 * sc), 1.8 * sc);
      _spot(canvas, Offset(base.dx + 4 * sc, capY - 7 * sc), 1.4 * sc);
      _spot(canvas, Offset(base.dx + 6 * sc, capY - 2 * sc), 1.1 * sc);
      _spot(canvas, Offset(base.dx - 7 * sc, capY - 1 * sc), 1.2 * sc);
    }

    if (kind == 2) {
      ctx.glow(canvas, Offset(base.dx, capY - 6 * sc), 12 * sc, const Color(0x338A6AD0));
    }
  }

  static void _spot(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFF7E8D0));
    canvas.drawCircle(c + Offset(-r * 0.25, -r * 0.3), r * 0.35, Paint()..color = const Color(0x55FFFFFF));
  }
}
