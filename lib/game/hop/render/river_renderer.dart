import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/domain/domain.dart';
import 'package:omaze/game/hop/render/render_context.dart';

/// Clean flat-vector river matching the reference:
/// bright teal bands, jagged navy submerged bases, white foam ticks,
/// terracotta plank logs, lime lily pads.
class RiverRenderer {
  const RiverRenderer._();

  static const _waterTop = Color(0xFF5CC8D8);
  static const _waterMid = Color(0xFF3EB0C4);
  static const _waterDeep = Color(0xFF2A90A8);
  static const _sub = Color(0xFF143A58);
  static const _foam = Color(0xFFE8F8FF);
  static const _wood = Color(0xFFB86840);
  static const _woodLite = Color(0xFFD49260);
  static const _woodDark = Color(0xFF8A4A2C);
  static const _woodDeep = Color(0xFF6E3420);
  static const _woodHi = Color(0xFFE8B888);
  static const _woodLine = Color(0xFF6A3018);
  static const _pad = Color(0xFF58B840);
  static const _padDark = Color(0xFF2E7828);
  static const _padLite = Color(0xFF78D050);

  static void draw(Canvas canvas, HopRow row, Rect rect, Offset origin, HopRenderContext ctx) {
    final flow = row.dir * math.max(row.speed, 0.22);
    final drift = ctx.time * ctx.tile * flow * 0.55;

    canvas.save();
    canvas.clipRect(rect);

    _drawWater(canvas, rect, origin, ctx);
    _drawSurfaceMarks(canvas, row, origin, drift, ctx);
    _drawFlowersAndGlints(canvas, row, origin, drift, ctx);

    for (var i = 0; i < row.movers.length; i++) {
      _drawSubmergedBase(canvas, row, row.movers[i], i, ctx);
    }
    for (var i = 0; i < row.movers.length; i++) {
      _drawFoamTicks(canvas, row, row.movers[i], i, ctx);
    }
    for (var i = 0; i < row.movers.length; i++) {
      _drawFloater(canvas, row, row.movers[i], i, ctx);
    }
    _drawBankReeds(canvas, row, ctx);

    canvas.restore();
  }

  static void drawRideRipple(Canvas canvas, Offset p, HopRow row, HopRenderContext ctx) {
    final pulse = 0.5 + 0.5 * ((math.sin(ctx.time * 3.6) + 1) / 2);
    canvas.drawOval(
      Rect.fromCenter(center: p + const Offset(0, 11), width: 28 + pulse * 5, height: 7.5),
      Paint()..color = Color.fromRGBO(200, 240, 255, 0.22 + pulse * 0.1),
    );
    for (var i = 0; i < 3; i++) {
      _foamTick(
        canvas,
        p + Offset(-10.0 + i * 10, 12.0 + math.sin(ctx.time * 4 + i) * 0.8),
        5.5 + pulse + i * 0.4,
      );
    }
  }

  /// Wood: heavier swell. Leaf: lighter, quicker bob.
  static double floaterBob(double x, int z, double time, {bool leaf = false}) {
    final phase = x * 1.05 + z * 0.6;
    if (leaf) {
      return math.sin(time * 2.4 + phase) * 2.2 + math.sin(time * 4.1 + phase * 1.5) * 0.8;
    }
    return math.sin(time * 1.55 + phase) * 2.6 + math.sin(time * 2.8 + phase * 1.4) * 0.75;
  }

  static double floaterTilt(double x, int z, double time, {bool leaf = false}) {
    final phase = x * 0.9 + z * 0.4;
    if (leaf) {
      return math.sin(time * 2.1 + phase) * 0.055 + math.sin(time * 3.6 + phase) * 0.02;
    }
    return math.sin(time * 1.35 + phase) * 0.038 + math.sin(time * 2.4 + phase * 1.2) * 0.014;
  }

  static double floaterRoll(double x, int z, double time, {bool leaf = false}) {
    if (leaf) {
      return math.sin(time * 2.0 + x * 0.8 + z) * 0.045;
    }
    return math.sin(time * 1.4 + x * 0.7 + z * 0.35) * 0.028;
  }

  // ── Water ──────────────────────────────────────────────────────

  static void _drawWater(Canvas canvas, Rect rect, Offset origin, HopRenderContext ctx) {
    final top = origin.dy - ctx.tile;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, origin.dy),
          const [_waterTop, _waterMid, _waterDeep],
          const [0.0, 0.45, 1.0],
        ),
    );
    // Soft animated swell bands.
    for (var i = 0; i < 4; i++) {
      final y = top + ctx.tile * (0.18 + i * 0.2) + math.sin(ctx.time * 1.2 + i) * 1.5;
      canvas.drawRect(
        Rect.fromLTWH(0, y, ctx.size.width, ctx.tile * 0.07),
        Paint()..color = Color.fromRGBO(255, 255, 255, 0.035 + (i % 2) * 0.02),
      );
    }
  }

  static void _drawSurfaceMarks(Canvas canvas, HopRow row, Offset origin, double drift, HopRenderContext ctx) {
    final span = ctx.size.width + 50.0;
    // Soft elongated depth ovals — drift with current.
    for (var i = 0; i < 9; i++) {
      final h = _hash(row.index, i + 3);
      final x = _cycle(i * 58.0 + (h % 28) + drift * (0.4 + (i % 3) * 0.08), span) - 16;
      final y = origin.dy - ctx.tile * (0.2 + (h % 5) * 0.12) + math.sin(ctx.time * 1.3 + i) * 1.2;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 26 + (h % 18).toDouble(), height: 5.5 + (h % 3).toDouble()),
        Paint()..color = const Color(0x26186078),
      );
    }
    // Flowing current ribbons.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final x = _cycle(i * 68.0 + row.index * 13 + drift * (0.95 + (i % 3) * 0.1), span) - 12;
      final y = origin.dy - ctx.tile * (0.18 + (i % 4) * 0.15);
      final len = 16.0 + (i % 3) * 9;
      final bend = math.sin(ctx.time * 1.65 + i + row.index) * 2.2;
      final path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + row.dir * len * 0.45, y + bend, x + row.dir * len, y + bend * 0.25);
      stroke
        ..color = Color.fromRGBO(208, 240, 248, 0.22 + (i % 3) * 0.06)
        ..strokeWidth = 1.35 + (i % 2) * 0.4;
      canvas.drawPath(path, stroke);
    }
  }

  static void _drawFlowersAndGlints(Canvas canvas, HopRow row, Offset origin, double drift, HopRenderContext ctx) {
    final span = ctx.size.width + 36.0;
    for (var i = 0; i < 5; i++) {
      final x = _cycle(i * 88.0 + row.index * 19 + drift * 0.25, span) - 6;
      final y = origin.dy - ctx.tile * (0.28 + (i % 3) * 0.16) + math.sin(ctx.time * 1.1 + i) * 0.8;
      if ((row.index + i).isEven) {
        _tinyFlower(canvas, Offset(x, y));
      } else {
        final tw = 0.45 + 0.55 * ((math.sin(ctx.time * 2.4 + i) + 1) / 2);
        canvas.drawCircle(
          Offset(x, y),
          1.3,
          Paint()..color = Color.fromRGBO(255, 255, 255, 0.35 * tw),
        );
      }
    }
  }

  static void _tinyFlower(Canvas canvas, Offset c) {
    for (var i = 0; i < 4; i++) {
      final a = i * (math.pi / 2) + 0.4;
      canvas.drawCircle(
        c + Offset(math.cos(a) * 2.0, math.sin(a) * 2.0),
        1.35,
        Paint()..color = const Color(0xEEFFFFFF),
      );
    }
    canvas.drawCircle(c, 1.15, Paint()..color = const Color(0xFFF0D860));
  }

  // ── Submerged base + foam (the signature look) ─────────────────

  static int _seed(HopRow row, Mover m, int i) => _hash(row.index * 97 + i * 53, (m.w * 40).round());

  static void _drawSubmergedBase(Canvas canvas, HopRow row, Mover m, int moverIndex, HopRenderContext ctx) {
    final leaf = row.pads;
    final bob = floaterBob(m.x, row.index, ctx.time, leaf: leaf);
    final p = ctx.tilePos(m.x, row.index + 0.18) + Offset(0, bob);
    final w = m.w * ctx.tile;
    final seed = _seed(row, m, moverIndex);
    final breath = 0.5 + 0.5 * math.sin(ctx.time * 2.4 + moverIndex);
    // Shadow compresses slightly when floater dips (physics cue).
    final dip = (bob / 3.0).clamp(-1.0, 1.0);

    final baseTop = p.dy + (leaf ? 3.5 : 4.5) + dip.abs() * 0.4;
    final baseH = (leaf ? 6.5 : 8.0) + breath * 0.7 - dip * 0.5;
    final path = Path();
    const teeth = 10;
    path.moveTo(p.dx - 2, baseTop);
    path.lineTo(p.dx + w + 2, baseTop);
    for (var i = teeth; i >= 0; i--) {
      final t = i / teeth;
      final x = p.dx - 2 + (w + 4) * t;
      final jag = ((seed + i * 17) % 5 - 2) * 1.0 + math.sin(ctx.time * 2.0 + i * 0.4) * 0.35;
      final y = baseTop + baseH + jag + math.sin(t * math.pi) * 1.1;
      path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = _sub.withValues(alpha: 0.75));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(p.dx + w * 0.5 + 1, baseTop + baseH * 0.4),
        width: w * 0.9,
        height: baseH * 0.55,
      ),
      Paint()..color = const Color(0x2A081020),
    );
  }

  static void _drawFoamTicks(Canvas canvas, HopRow row, Mover m, int moverIndex, HopRenderContext ctx) {
    final leaf = row.pads;
    final bob = floaterBob(m.x, row.index, ctx.time, leaf: leaf);
    final p = ctx.tilePos(m.x, row.index + 0.18) + Offset(0, bob);
    final w = m.w * ctx.tile;
    final y = p.dy + (leaf ? 4.5 : 5.5);
    final pulse = 0.5 + 0.5 * math.sin(ctx.time * 3.0 + moverIndex);
    final heave = bob.abs() / 3.2;

    final count = leaf ? 3 : 4 + (w / ctx.tile).round().clamp(0, 2);
    for (var i = 0; i < count; i++) {
      final t = (i + 0.5) / count;
      final x = p.dx + w * t;
      _foamTick(
        canvas,
        Offset(x, y + math.sin(ctx.time * 3.4 + i) * 0.8),
        4.2 + pulse + heave,
      );
    }
    // Bow splash grows with motion direction.
    _foamTick(canvas, Offset(p.dx + (row.dir > 0 ? w + 4 : -4), y), 6.0 + pulse + heave * 1.2);
    _foamTick(canvas, Offset(p.dx + (row.dir > 0 ? -3 : w + 3), y + 1), 4.8 + pulse * 0.6);

    // Soft trailing wash ovals.
    final stern = p.dx + (row.dir > 0 ? -2 : w + 2);
    for (var i = 1; i <= 3; i++) {
      final t = i / 3;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(stern - row.dir * (9.0 + i * 10), y + 1 + math.sin(ctx.time * 2.2 + i) * 0.7),
          width: 10 + (1 - t) * 8,
          height: 3.2,
        ),
        Paint()
          ..color = Color.fromRGBO(220, 248, 255, 0.18 * (1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  static void _foamTick(Canvas canvas, Offset c, double size) {
    final path = Path()
      ..moveTo(c.dx - size * 0.55, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + size * 0.55, c.dx + size * 0.55, c.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = _foam.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.55
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Floaters ───────────────────────────────────────────────────

  static void _drawFloater(Canvas canvas, HopRow row, Mover m, int moverIndex, HopRenderContext ctx) {
    final leaf = row.pads;
    final bob = floaterBob(m.x, row.index, ctx.time, leaf: leaf);
    final p = ctx.tilePos(m.x, row.index + 0.18) + Offset(0, bob);
    if (leaf) {
      _drawPad(canvas, p, m, row, moverIndex, ctx);
    } else {
      _drawLog(canvas, p, m, row, moverIndex, ctx, bob);
    }
  }

  /// Natural floating timber — bark ridges, uneven grain, soft moss, wet base.
  static void _drawLog(
    Canvas canvas,
    Offset p,
    Mover m,
    HopRow row,
    int moverIndex,
    HopRenderContext ctx,
    double bob,
  ) {
    final w = m.w * ctx.tile;
    final h = ctx.tile * 0.44;
    final seed = _seed(row, m, moverIndex);
    final tilt = floaterTilt(m.x, row.index, ctx.time);
    final roll = floaterRoll(m.x, row.index, ctx.time);
    final squash = 1.0 + (bob / 8.0).clamp(-0.04, 0.04);
    final top = p.dy - h * (0.56 + roll * 0.2);
    final bodyH = h * squash;
    final midY = top + bodyH * 0.5;

    canvas.save();
    final pivot = Offset(p.dx + w * 0.5, p.dy);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(tilt);
    canvas.translate(-pivot.dx, -pivot.dy);

    // Slightly irregular bark silhouette (worn log, not a perfect pill).
    final body = Path();
    const steps = 14;
    body.moveTo(p.dx + 6, top);
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = p.dx + 6 + (w - 12) * t;
      final bump = math.sin(t * math.pi * 3 + seed) * 0.9 + ((seed + i * 11) % 5 - 2) * 0.22;
      body.lineTo(x, top + bump * (t > 0.08 && t < 0.92 ? 1.0 : 0.2));
    }
    body.quadraticBezierTo(p.dx + w, midY - 2, p.dx + w - 2, midY);
    body.quadraticBezierTo(p.dx + w, midY + 3, p.dx + w - 6, top + bodyH);
    for (var i = steps; i >= 0; i--) {
      final t = i / steps;
      final x = p.dx + 6 + (w - 12) * t;
      final bump = math.sin(t * math.pi * 2.4 + seed * 0.7) * 0.55;
      body.lineTo(x, top + bodyH - bump);
    }
    body.quadraticBezierTo(p.dx, midY + 3, p.dx + 2, midY);
    body.quadraticBezierTo(p.dx, midY - 2, p.dx + 6, top);
    body.close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(p.dx, top),
          Offset(p.dx, top + bodyH),
          const [
            _woodHi,
            _woodLite,
            _wood,
            _woodDark,
            _woodDeep,
          ],
          const [0.0, 0.18, 0.45, 0.78, 1.0],
        ),
    );

    // Soft lengthwise bark warmth variation (not flat plastic).
    for (var i = 0; i < 4; i++) {
      final t0 = 0.08 + i * 0.22 + ((seed + i) % 5) * 0.01;
      final tw = 0.16 + ((seed + i * 7) % 4) * 0.02;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(p.dx + w * t0, top + 3, w * tw, bodyH - 6),
          const Radius.circular(5),
        ),
        Paint()..color = Color.fromRGBO(120, 55, 28, 0.07 + (i % 2) * 0.04),
      );
    }

    // Specular rim — broken, not a continuous plastic stripe.
    final rim = Path();
    rim.moveTo(p.dx + 10, top + 3.2);
    for (var i = 0; i <= 8; i++) {
      final t = i / 8;
      final x = p.dx + 10 + (w - 20) * t;
      final y = top + 3.2 + math.sin(t * math.pi * 2.2 + seed) * 0.7;
      rim.lineTo(x, y);
    }
    canvas.drawPath(
      rim,
      Paint()
        ..color = const Color(0x77FFE8C8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round,
    );

    // Vertical bark ridges (organic seams, uneven spacing).
    final ridges = 4 + (w > ctx.tile * 1.3 ? 1 : 0) + (w > ctx.tile * 1.65 ? 1 : 0);
    for (var i = 1; i < ridges; i++) {
      final jitter = ((seed + i * 19) % 7 - 3) * 0.35;
      final x = p.dx + w * (i / ridges) + jitter;
      final crack = Path()
        ..moveTo(x, top + 4.5)
        ..quadraticBezierTo(
          x + ((seed + i).isEven ? 1.2 : -1.0),
          midY,
          x + ((seed + i * 3) % 3 - 1) * 0.6,
          top + bodyH - 4.5,
        );
      canvas.drawPath(
        crack,
        Paint()
          ..color = _woodLine.withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.35
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        crack,
        Paint()
          ..color = const Color(0x28FFF0D8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4),
      );
    }

    // Wavy growth rings / grain strokes along the length.
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var g = 0; g < 5; g++) {
      final yBase = top + bodyH * (0.28 + g * 0.12);
      final path = Path();
      final segs = 10;
      for (var i = 0; i <= segs; i++) {
        final t = i / segs;
        final x = p.dx + 9 + (w - 18) * t;
        final y = yBase +
            math.sin(t * math.pi * 2.6 + g + seed * 0.01) * 1.1 +
            math.sin(t * math.pi * 5 + g * 1.7) * 0.35;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      grain
        ..color = Color.fromRGBO(90, 40, 18, 0.14 + (g % 2) * 0.06)
        ..strokeWidth = 1.0 + (g == 2 ? 0.35 : 0.0);
      canvas.drawPath(path, grain);
    }

    // Soft moss / lichen patches (warm green, not black knots).
    for (var i = 0; i < 3; i++) {
      final hx = p.dx + w * (0.18 + i * 0.28 + ((seed + i) % 5) * 0.015);
      final hy = top + bodyH * (0.22 + ((seed + i * 5) % 4) * 0.08);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(hx, hy),
          width: 7 + (i % 2) * 3.5,
          height: 3.2 + (i % 2),
        ),
        Paint()..color = Color.fromRGBO(70, 110, 48, 0.16 + (i % 2) * 0.05),
      );
    }

    // Worn end caps — darker oval, soft inner highlight (cut timber feel).
    for (final end in [p.dx + 5.5, p.dx + w - 5.5]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(end, midY), width: 11, height: bodyH * 0.78),
        Paint()..color = const Color(0x558A4428),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(end, midY - 0.5), width: 5.5, height: bodyH * 0.38),
        Paint()..color = const Color(0x33F0C8A0),
      );
    }

    // Wet lower band where water kisses the bark.
    final wetY = top + bodyH * 0.72 + math.sin(ctx.time * 3.0 + moverIndex) * 0.6;
    final wet = Path()
      ..moveTo(p.dx + 8, wetY)
      ..quadraticBezierTo(p.dx + w * 0.5, wetY + 1.4, p.dx + w - 8, wetY - 0.3);
    canvas.drawPath(
      wet,
      Paint()
        ..color = const Color(0x5588C8D8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      wet,
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xCC5A2814)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35,
    );

    canvas.restore();
  }

  /// Lighter, livelier leaf — rock + pitch with the swell.
  static void _drawPad(Canvas canvas, Offset p, Mover m, HopRow row, int moverIndex, HopRenderContext ctx) {
    final c = Offset(p.dx + m.w * ctx.tile / 2, p.dy - ctx.tile * 0.12);
    final w = m.w * ctx.tile;
    final h = ctx.tile * 0.38;
    final rock = floaterTilt(m.x, row.index, ctx.time, leaf: true);
    final spin = floaterRoll(m.x, row.index, ctx.time, leaf: true);
    final bob = floaterBob(m.x, row.index, ctx.time, leaf: true);
    final pitch = (bob / 40.0).clamp(-0.03, 0.03);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rock + spin);
    canvas.scale(1.0, 1.0 + pitch);
    canvas.translate(-c.dx, -c.dy);

    final pad = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(c.dx + 10, c.dy - 2.5)
      ..arcTo(Rect.fromCenter(center: c, width: w, height: h), -0.22, math.pi * 2 - 0.72, false)
      ..close();

    canvas.drawPath(pad, Paint()..color = _pad);
    canvas.drawPath(
      pad,
      Paint()
        ..color = _padDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-w * 0.12, -h * 0.1), width: w * 0.35, height: h * 0.28),
      Paint()..color = _padLite.withValues(alpha: 0.5),
    );

    final vein = Paint()
      ..color = _padDark.withValues(alpha: 0.42)
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final a = -0.55 + i * 0.55;
      canvas.drawLine(c, c + Offset(math.cos(a) * w * 0.34, math.sin(a) * h * 0.3), vein);
    }

    // Flower bobbles slightly opposite to the leaf pitch.
    final f = c + Offset(6, -4 - pitch * 20);
    canvas.drawCircle(f, 3.1, Paint()..color = const Color(0xFFE85D8A));
    canvas.drawCircle(f, 1.25, Paint()..color = const Color(0xFFFFF1B0));

    canvas.restore();
  }

  static void _drawBankReeds(Canvas canvas, HopRow row, HopRenderContext ctx) {
    for (final lane in [-1.0, WorldGenerator.lanes.toDouble()]) {
      final base = ctx.tilePos(lane + 0.35, row.index + 0.52);
      final sway = math.sin(ctx.time * 1.2 + lane + row.index) * 2.4;
      for (var i = 0; i < 3; i++) {
        final tip = Offset(base.dx + i * 5 + sway * 1.3, base.dy - 15 - i * 2);
        final path = Path()
          ..moveTo(base.dx + i * 5, base.dy + 5)
          ..quadraticBezierTo(base.dx + i * 5 + sway, base.dy - 6, tip.dx, tip.dy);
        canvas.drawPath(
          path,
          Paint()
            ..color = i.isEven ? const Color(0xAA2A5838) : const Color(0xBB1A3E28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.7
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────

  static double _cycle(double value, double span) {
    final m = value % span;
    return m < 0 ? m + span : m;
  }

  static int _hash(int a, int b) {
    var h = a * 374761393 + b * 668265263;
    h = (h ^ (h >> 13)) * 1274126177;
    return h & 0x7fffffff;
  }
}
