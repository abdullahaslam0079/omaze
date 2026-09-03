import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/render/render_context.dart';

/// Draws stylized trees with a chunky, toy-like aesthetic.
class TreeRenderer {
  const TreeRenderer._();

  static void draw(Canvas canvas, int lane, int z, HopRenderContext ctx) {
    final p = ctx.tilePos(lane + 0.5, z + 0.25);
    final kind = (lane * 17 + z * 31) % 3;
    final seed = (lane * 7 + z * 13) % 100;

    // Subtle, gentle sway — trees shouldn't dance
    final sway = math.sin(ctx.time * 0.6 + lane * 1.1 + z * 0.5) * 1.2;

    // Per-tree size variation
    final sc = 0.92 + (seed % 12) * 0.015; // 0.92–1.10

    if (kind == 2) {
      _drawPine(canvas, p, sway, sc, seed, ctx);
    } else {
      _drawRound(canvas, p, sway, sc, seed, kind, ctx);
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  ROUND / DECIDUOUS TREE — chunky toy style
  // ══════════════════════════════════════════════════════════════
  static void _drawRound(
    Canvas canvas, Offset p, double sway, double sc,
    int seed, int kind, HopRenderContext ctx,
  ) {
    final s = sc;
    final bool purple = kind == 1;

    // ── Shadow on ground ──
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(p.dx + 2, p.dy + 18 * s),
        width: 44 * s,
        height: 12 * s,
      ),
      Paint()
        ..color = const Color(0x38000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── Trunk ──
    final tx = p.dx + sway * 0.15;
    final trunkW = 7.0 * s;
    final trunkTop = p.dy - 18 * s;
    final trunkBot = p.dy + 16 * s;

    // Main trunk body
    final trunkPath = Path()
      ..moveTo(tx - trunkW * 0.65, trunkBot)
      ..cubicTo(
        tx - trunkW * 0.55, p.dy,
        tx - trunkW * 0.35 + sway * 0.08, trunkTop + 12 * s,
        tx - trunkW * 0.25 + sway * 0.12, trunkTop,
      )
      ..lineTo(tx + trunkW * 0.25 + sway * 0.12, trunkTop)
      ..cubicTo(
        tx + trunkW * 0.35 + sway * 0.08, trunkTop + 12 * s,
        tx + trunkW * 0.55, p.dy,
        tx + trunkW * 0.65, trunkBot,
      )
      ..close();
    canvas.drawPath(trunkPath, Paint()..color = const Color(0xFF5C3416));

    // Trunk light side
    canvas.drawPath(
      Path()
        ..moveTo(tx + trunkW * 0.1, trunkBot)
        ..cubicTo(
          tx + trunkW * 0.15, p.dy,
          tx + trunkW * 0.2 + sway * 0.06, trunkTop + 12 * s,
          tx + trunkW * 0.2 + sway * 0.1, trunkTop + 2 * s,
        )
        ..lineTo(tx + trunkW * 0.25 + sway * 0.12, trunkTop)
        ..cubicTo(
          tx + trunkW * 0.35 + sway * 0.08, trunkTop + 12 * s,
          tx + trunkW * 0.55, p.dy,
          tx + trunkW * 0.65, trunkBot,
        )
        ..close(),
      Paint()..color = const Color(0x40906838),
    );

    // Root bumps
    canvas.drawOval(
      Rect.fromCenter(center: Offset(tx - 8 * s, trunkBot + 2), width: 14 * s, height: 6 * s),
      Paint()..color = const Color(0xFF4A2A14),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(tx + 9 * s, trunkBot + 2), width: 12 * s, height: 5 * s),
      Paint()..color = const Color(0xFF4A2A14),
    );

    // ── Crown — big chunky layered canopy ──
    final cx = p.dx + sway * 0.4;
    final cy = p.dy - 32 * s;

    // Color palette
    final Color dark, mid, bright;
    if (purple) {
      dark = const Color(0xFF3A2468);
      mid = const Color(0xFF5A3C90);
      bright = const Color(0xFF7A58C0);
    } else {
      dark = const Color(0xFF1A5228);
      mid = const Color(0xFF28783C);
      bright = const Color(0xFF3CA84E);
    }

    // Back shadow mass
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 8 * s), width: 52 * s, height: 32 * s),
      Paint()..color = dark,
    );

    // Main body — two big overlapping ovals
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 6 * s, cy + 2 * s), width: 42 * s, height: 34 * s),
      Paint()..color = mid,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 7 * s, cy + 1 * s), width: 40 * s, height: 32 * s),
      Paint()..color = mid,
    );

    // Bright top dome
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 2 * s, cy - 6 * s), width: 36 * s, height: 24 * s),
      Paint()..color = bright,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 5 * s, cy - 4 * s), width: 28 * s, height: 20 * s),
      Paint()..color = bright,
    );

    // Highlight crescent (top-left light source)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 4 * s, cy - 12 * s), width: 20 * s, height: 10 * s),
      Paint()..color = const Color(0x28FFFFFF),
    );

    // Chunky bump details around edge
    final bumpColor = mid.withAlpha(200);
    for (var i = 0; i < 6; i++) {
      final a = -1.0 + i * 1.1;
      final bx = math.cos(a) * 22 * s;
      final by = math.sin(a) * 14 * s + 4 * s;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + bx, cy + by), width: 14 * s, height: 10 * s),
        Paint()..color = bumpColor,
      );
    }

    // ── Decorations ──
    if (purple) {
      // Glowing berries / magical fruits
      ctx.glow(canvas, Offset(cx, cy), 18 * s, const Color(0x228A6AD0));
      _dot(canvas, Offset(cx - 10 * s, cy - 4 * s), 2.8 * s, const Color(0xFFE8C36A));
      _dot(canvas, Offset(cx + 12 * s, cy - 8 * s), 2.4 * s, const Color(0xFFE8C36A));
      _dot(canvas, Offset(cx + 2 * s, cy + 6 * s), 2.0 * s, const Color(0xFFF0D870));
      _dot(canvas, Offset(cx - 14 * s, cy + 4 * s), 1.8 * s, const Color(0xFFE8C36A));
      _dot(canvas, Offset(cx + 8 * s, cy + 2 * s), 2.2 * s, const Color(0xFFF0D870));
    } else {
      // Cute flowers / berries on green trees
      _flower(canvas, Offset(cx - 10 * s, cy + 2 * s), 2.4 * s, const Color(0xFFE85D8A));
      _flower(canvas, Offset(cx + 11 * s, cy - 6 * s), 2.0 * s, const Color(0xFFF4C542));
      _flower(canvas, Offset(cx + 1 * s, cy + 8 * s), 1.8 * s, const Color(0xFFE85D8A));
      _flower(canvas, Offset(cx - 6 * s, cy - 10 * s), 1.6 * s, const Color(0xFFF4C542));
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  PINE / CONIFER — clean triangular silhouette
  // ══════════════════════════════════════════════════════════════
  static void _drawPine(
    Canvas canvas, Offset p, double sway, double sc,
    int seed, HopRenderContext ctx,
  ) {
    final s = sc;

    // ── Shadow ──
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(p.dx + 2, p.dy + 18 * s),
        width: 36 * s,
        height: 10 * s,
      ),
      Paint()
        ..color = const Color(0x38000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── Trunk ──
    final tx = p.dx;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(tx + sway * 0.08, p.dy + 2 * s),
          width: 8 * s,
          height: 30 * s,
        ),
        Radius.circular(2 * s),
      ),
      Paint()..color = const Color(0xFF4E2C12),
    );
    // Trunk highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(tx + 1.5 * s + sway * 0.08, p.dy + 2 * s),
          width: 3 * s,
          height: 28 * s,
        ),
        Radius.circular(1.5 * s),
      ),
      Paint()..color = const Color(0x40805828),
    );

    // ── Foliage tiers — clean pointed triangles with rounded bases ──
    final tiers = [
      (y: -4.0,  w: 22.0, h: 18.0, c: const Color(0xFF163E22)),
      (y: -16.0, w: 18.0, h: 16.0, c: const Color(0xFF1E5830)),
      (y: -26.0, w: 14.0, h: 14.0, c: const Color(0xFF287840)),
      (y: -34.0, w: 10.0, h: 12.0, c: const Color(0xFF38A050)),
      (y: -40.0, w: 6.0,  h: 10.0, c: const Color(0xFF48B860)),
    ];

    for (final t in tiers) {
      final tierSway = sway * (0.2 + t.y.abs() * 0.012);
      final tipX = tx + tierSway;
      final tipY = p.dy + (t.y - t.h * 0.5) * s;
      final baseY = p.dy + (t.y + t.h * 0.35) * s;
      final halfW = t.w * 0.5 * s;

      // Dark underside
      final dark = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(tipX - halfW * 1.1 + tierSway * 0.2, baseY + 2 * s)
        ..quadraticBezierTo(tipX + tierSway * 0.1, baseY + 5 * s, tipX + halfW * 1.1 + tierSway * 0.2, baseY + 2 * s)
        ..close();
      canvas.drawPath(dark, Paint()..color = Color.fromARGB(t.c.alpha, (t.c.red * 0.7).round(), (t.c.green * 0.7).round(), (t.c.blue * 0.7).round()));

      // Main tier shape
      final path = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(tipX - halfW + tierSway * 0.2, baseY)
        ..quadraticBezierTo(tipX + tierSway * 0.1, baseY + 3 * s, tipX + halfW + tierSway * 0.2, baseY)
        ..close();
      canvas.drawPath(path, Paint()..color = t.c);

      // Highlight on left side (light from top-left)
      final hlPath = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(tipX - halfW * 0.35 + tierSway * 0.15, baseY - 1 * s)
        ..lineTo(tipX - halfW * 0.05, tipY + t.h * 0.35 * s)
        ..close();
      canvas.drawPath(hlPath, Paint()..color = const Color(0x18FFFFFF));
    }

    // Snow-cap / light highlight at tip
    final topY = p.dy - 46 * s;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(tx + sway * 0.3, topY + 4 * s),
        width: 6 * s,
        height: 4 * s,
      ),
      Paint()..color = const Color(0x40FFFFFF),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════

  /// Simple dot with specular highlight.
  static void _dot(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(
      c + Offset(-r * 0.25, -r * 0.3),
      r * 0.35,
      Paint()..color = const Color(0x55FFFFFF),
    );
  }

  /// Tiny 4-petal flower.
  static void _flower(Canvas canvas, Offset c, double r, Color color) {
    final petalR = r * 0.65;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi * 0.5 + 0.4;
      canvas.drawCircle(
        c + Offset(math.cos(a) * r * 0.5, math.sin(a) * r * 0.5),
        petalR,
        Paint()..color = color,
      );
    }
    canvas.drawCircle(c, r * 0.35, Paint()..color = const Color(0xFFFFF4CC));
  }
}
