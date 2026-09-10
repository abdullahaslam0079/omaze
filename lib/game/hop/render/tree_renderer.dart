import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/domain/world_generator.dart';
import 'package:omaze/game/hop/render/render_context.dart';

/// One static storybook hero tree.
///
/// Visual construction (not a circle stack):
///   planted base → trunk / Y-branches → ONE connected canopy silhouette
///   → clipped interior depth + moon rim (light from upper-right)
///
/// Interior foliage is always clipped to the crown path so overlapping
/// masses read as volume inside one living object, not separate bushes.
class TreeRenderer {
  const TreeRenderer._();

  static final Paint _fill = Paint()..style = PaintingStyle.fill;
  static final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // ── Hero proportions — wide crown, short supporting trunk ──
  static const double sizeScale = 1.0;
  static const double canopyW = 78;
  static const double canopyH = 52;
  static const double trunkH = 22;
  static const double trunkW = 12;

  // ── Moonlit meadow palette (moon sits upper-right) ──
  static const Color _trunkDeep = Color(0xFF2E1C10);
  static const Color _trunkMid = Color(0xFF4E3218);
  static const Color _trunkLite = Color(0xFF7A5830);
  static const Color _night = Color(0xFF1C1430);
  static const Color _moon = Color(0xFFF2DCA8);
  static const Color _deep = Color(0xFF0A241C);
  static const Color _body = Color(0xFF164830);
  static const Color _mid = Color(0xFF246848);
  static const Color _front = Color(0xFF348858);
  static const Color _lit = Color(0xFF4CA870);
  static const Color _rim = Color(0xFFA8C878);
  static const Color _moss = Color(0xFF183828);
  static const Color _mossLite = Color(0xFF2A5840);

  static void draw(Canvas canvas, int lane, int z, HopRenderContext ctx) {
    final edge = lane < 0 || lane >= WorldGenerator.lanes;
    final seed = (lane * 7919 + z * 104729).abs();
    final depth = 0.38 + (seed % 10) * 0.028;
    final side = edge
        ? (lane < 0 ? -0.42 : 0.42)
        : ((seed % 7) - 3) * 0.012;
    final p = ctx.tilePos(lane + 0.5 + side, z + depth);

    // Same hero silhouette everywhere — only tiny placement scale.
    final s = sizeScale * (0.96 + (seed % 6) * 0.012) * (edge ? 0.9 : 1.0);
    final darken = edge ? 0.28 : (depth > 0.55 ? 0.08 : 0.0);

    _drawHero(canvas, p, s, darken);
  }

  /// Draws the hero at [origin] (ground contact). Useful for previews.
  static void drawHeroAt(Canvas canvas, Offset origin, {double scale = 1}) {
    _drawHero(canvas, origin, scale, 0);
  }

  static void _drawHero(Canvas canvas, Offset p, double s, double darken) {
    final tx = p.dx;
    final ground = p.dy + 5 * s;

    final tw = trunkW * s;
    final th = trunkH * s;
    final cw = canopyW * s;
    final ch = canopyH * s;

    final crownY = ground - th;
    // Wide canopy sits low over the fork — reference proportions.
    final cx = tx + 1.2 * s;
    final cy = crownY - ch * 0.38;

    _groundContact(canvas, Offset(tx, ground), tw, cw, s);
    _understory(canvas, Offset(tx, ground), tw, s);

    // 1. Back canopy — cooler connected mass slightly larger / behind trunk.
    final back = _canopySilhouette(
      cx - 2 * s,
      cy + 4 * s,
      cw * 1.08,
      ch * 1.06,
      bias: -0.04,
    );
    _fill.color = _shade(_deep, darken, cool: 0.35);
    canvas.drawPath(back, _fill);

    // 2. Skeleton — trunk + branches the canopy grows around.
    _trunkAndBranches(canvas, Offset(tx, ground), crownY, tw, s);

    // 3. Main connected canopy + ALL interior painting clipped to it.
    final crown = _canopySilhouette(cx, cy, cw, ch, bias: 0.04);
    _fill.color = _shade(_body, darken, cool: 0.06);
    canvas.drawPath(crown, _fill);

    canvas.save();
    canvas.clipPath(crown);
    _paintCrownInterior(canvas, cx, cy, cw, ch, s, darken);
    canvas.restore();

    // Soft outer rim stroke so the silhouette stays soft, not hard-edged.
    _stroke
      ..color = _shade(_body, darken, cool: 0.15).withValues(alpha: 0.35)
      ..strokeWidth = 1.6 * s;
    canvas.drawPath(crown, _stroke);

    // Branch tips peeking just under the crown hollow (outside clip).
    _branchTips(canvas, Offset(tx, crownY), tw, s);

    _frontPlanting(canvas, Offset(tx, ground), tw, s);
  }

  /// One connected, irregular crown — designed lobes, not a circle stack.
  ///
  /// Polar radii are hand-tuned for a wide, soft, asymmetrical silhouette
  /// with a scooped underside over the trunk/fork.
  static Path _canopySilhouette(
    double cx,
    double cy,
    double w,
    double h, {
    double bias = 0,
  }) {
    // Cloud-like billows around a single mass. Right side fuller when bias > 0.
    const angles = <double>[
      -0.20, 0.15, 0.55, 0.95, 1.35, 1.75, 2.15, 2.55,
      2.95, 3.35, 3.75, 4.15, 4.55, 4.95, 5.35, 5.75, 6.05,
    ];
    final radii = <double>[
      0.98 + bias, // right mid — moon facing
      1.05 + bias * 0.5, // right bulge
      0.92 + bias * 0.3, // upper-right
      0.88,
      0.94, // top-right cloud
      0.86, // top
      0.90, // top-left cloud
      0.82,
      0.88, // left mid
      0.78, // lower-left tuck
      0.70, // bottom-left scallop
      0.62, // over trunk left
      0.58, // scooped belly over fork
      0.64, // over trunk right
      0.74, // bottom-right scallop
      0.86,
      0.96 + bias * 0.35,
    ];

    final pts = <Offset>[];
    for (var i = 0; i < angles.length; i++) {
      pts.add(Offset(
        cx + math.cos(angles[i]) * w * 0.5 * radii[i],
        cy + math.sin(angles[i]) * h * 0.5 * radii[i],
      ));
    }
    pts.add(pts.first);

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final mx = (a.dx + b.dx) * 0.5;
      final my = (a.dy + b.dy) * 0.5;
      // Pull control outward so lobes feel soft / cloudy.
      path.quadraticBezierTo(
        mx + (mx - cx) * 0.22,
        my + (my - cy) * 0.22,
        b.dx,
        b.dy,
      );
    }
    path.close();
    return path;
  }

  /// Soft irregular foliage mass — only drawn inside the clipped crown.
  static Path _mass(Offset c, double rx, double ry, {double rot = 0}) {
    const n = 12;
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final t = i / n * math.pi * 2;
      final wobble =
          0.86 + 0.12 * math.sin(t * 2.2 + 0.4) + 0.08 * math.cos(t * 3.1);
      final x = math.cos(t) * rx * wobble;
      final y = math.sin(t) * ry * wobble;
      final xr = x * math.cos(rot) - y * math.sin(rot);
      final yr = x * math.sin(rot) + y * math.cos(rot);
      pts.add(Offset(c.dx + xr, c.dy + yr));
    }
    pts.add(pts.first);

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final mx = (a.dx + b.dx) * 0.5;
      final my = (a.dy + b.dy) * 0.5;
      path.quadraticBezierTo(
        mx + (mx - c.dx) * 0.15,
        my + (my - c.dy) * 0.15,
        b.dx,
        b.dy,
      );
    }
    path.close();
    return path;
  }

  /// All volume / lighting happens inside the clipped silhouette.
  static void _paintCrownInterior(
    Canvas canvas,
    double cx,
    double cy,
    double cw,
    double ch,
    double s,
    double darken,
  ) {
    // Cool left volume.
    _fill.color = _shade(_deep, darken, cool: 0.28);
    canvas.drawPath(
      _mass(Offset(cx - cw * 0.22, cy + ch * 0.02), cw * 0.34, ch * 0.38, rot: -0.2),
      _fill,
    );

    // Hollow over the fork — darker so branches read through.
    _fill.color = _shade(_deep, darken, cool: 0.4);
    canvas.drawPath(
      _mass(Offset(cx - cw * 0.02, cy + ch * 0.22), cw * 0.30, ch * 0.22, rot: 0.05),
      _fill,
    );
    canvas.drawPath(
      _mass(Offset(cx + cw * 0.12, cy + ch * 0.26), cw * 0.22, ch * 0.16, rot: 0.25),
      _fill,
    );

    // Soft scalloped underside (still clipped — reads as one belly).
    for (var i = 0; i < 5; i++) {
      final t = (i - 2) / 2.1;
      _fill.color = _shade(_deep, darken, cool: t < 0 ? 0.32 : 0.18);
      canvas.drawPath(
        _mass(
          Offset(cx + t * cw * 0.34, cy + ch * 0.34 + (i == 2 ? 1.5 * s : 0)),
          (10 + (i == 2 ? 4 : 0)) * (cw / canopyW),
          (7.5 + (i.isEven ? 1.2 : 0)) * (ch / canopyH),
        ),
        _fill,
      );
    }

    // Mid greens — overlapping masses that merge inside the clip.
    _fill.color = _shade(_mid, darken, cool: 0.1);
    canvas.drawPath(
      _mass(Offset(cx - cw * 0.18, cy - ch * 0.06), cw * 0.32, ch * 0.34, rot: -0.18),
      _fill,
    );
    canvas.drawPath(
      _mass(Offset(cx + cw * 0.06, cy - ch * 0.14), cw * 0.36, ch * 0.32, rot: 0.08),
      _fill,
    );

    _fill.color = _shade(_mid, darken, warm: 0.05);
    canvas.drawPath(
      _mass(Offset(cx + cw * 0.22, cy - ch * 0.02), cw * 0.34, ch * 0.36, rot: 0.22),
      _fill,
    );

    // Front / lit clusters.
    _fill.color = _shade(_front, darken, warm: 0.08);
    canvas.drawPath(
      _mass(Offset(cx - cw * 0.04, cy - ch * 0.20), cw * 0.30, ch * 0.28, rot: -0.08),
      _fill,
    );
    canvas.drawPath(
      _mass(Offset(cx + cw * 0.14, cy - ch * 0.18), cw * 0.28, ch * 0.26, rot: 0.12),
      _fill,
    );

    _fill.color = _shade(_lit, darken, warm: 0.1);
    canvas.drawPath(
      _mass(Offset(cx + cw * 0.08, cy - ch * 0.28), cw * 0.22, ch * 0.18, rot: 0.05),
      _fill,
    );

    // Moon rim — warm upper-right only, still clipped to crown.
    _fill.color = Color.lerp(_rim, _moon, 0.35)!.withValues(alpha: 0.55);
    canvas.drawPath(
      _mass(Offset(cx + cw * 0.30, cy - ch * 0.08), cw * 0.16, ch * 0.30, rot: 0.4),
      _fill,
    );
    canvas.drawPath(
      _mass(Offset(cx + cw * 0.22, cy - ch * 0.30), cw * 0.20, ch * 0.16, rot: -0.1),
      _fill,
    );

    _fill.color = Color.lerp(_rim, _moon, 0.5)!.withValues(alpha: 0.48);
    canvas.drawPath(
      _mass(Offset(cx + cw * 0.28, cy - ch * 0.28), cw * 0.12, ch * 0.11),
      _fill,
    );

    _fill.color = _moon.withValues(alpha: 0.22);
    canvas.drawPath(
      _mass(Offset(cx + cw * 0.32, cy - ch * 0.24), cw * 0.07, ch * 0.06),
      _fill,
    );

    // Tiny leaf-suggestion dots on the lit face (subtle, not noise).
    _fill.color = Color.lerp(_lit, _moon, 0.25)!.withValues(alpha: 0.35);
    final dots = <Offset>[
      Offset(cx + cw * 0.10, cy - ch * 0.22),
      Offset(cx + cw * 0.18, cy - ch * 0.14),
      Offset(cx + cw * 0.02, cy - ch * 0.10),
      Offset(cx - cw * 0.08, cy - ch * 0.16),
      Offset(cx + cw * 0.24, cy - ch * 0.02),
    ];
    for (final d in dots) {
      canvas.drawCircle(d, 1.35 * s, _fill);
    }
  }

  // ── Trunk / branches ──

  static void _trunkAndBranches(
    Canvas canvas,
    Offset base,
    double topY,
    double tw,
    double s,
  ) {
    final halfBot = tw * 0.78;
    final halfMid = tw * 0.44;
    final halfTop = tw * 0.30;
    final midY = base.dy * 0.40 + topY * 0.60;
    final lowY = base.dy - tw * 0.45;
    const lean = 1.8; // slight organic lean toward moon

    // Continuous flare → taper → fork collar.
    final trunk = Path()
      ..moveTo(base.dx - halfBot * 1.4, base.dy + 0.8 * s)
      ..quadraticBezierTo(base.dx - halfBot, lowY, base.dx - halfMid, midY)
      ..quadraticBezierTo(
        base.dx - halfTop * 0.9 + lean * s * 0.1,
        topY + 5 * s,
        base.dx - halfTop + lean * s * 0.15,
        topY,
      )
      ..lineTo(base.dx - halfTop * 0.2 + lean * s * 0.25, topY - 2.5 * s)
      ..quadraticBezierTo(
        base.dx + lean * s * 0.3,
        topY - 5 * s,
        base.dx + halfTop * 0.45 + lean * s * 0.35,
        topY - 2.5 * s,
      )
      ..lineTo(base.dx + halfTop + lean * s * 0.4, topY)
      ..quadraticBezierTo(
        base.dx + halfTop * 0.95 + lean * s * 0.15,
        topY + 5 * s,
        base.dx + halfMid,
        midY,
      )
      ..quadraticBezierTo(
        base.dx + halfBot * 0.95,
        lowY,
        base.dx + halfBot * 1.25,
        base.dy + 0.8 * s,
      )
      ..quadraticBezierTo(
        base.dx,
        base.dy + 3.8 * s,
        base.dx - halfBot * 1.4,
        base.dy + 0.8 * s,
      )
      ..close();

    _fill.color = _trunkMid;
    canvas.drawPath(trunk, _fill);

    // Left cool shade.
    _fill.color = Color.lerp(_trunkDeep, _night, 0.18)!.withValues(alpha: 0.7);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - halfBot * 1.3, base.dy + 0.4 * s)
        ..quadraticBezierTo(base.dx - halfBot * 0.85, lowY, base.dx - halfMid * 0.85, midY)
        ..quadraticBezierTo(
          base.dx - halfTop * 0.4,
          topY + 3 * s,
          base.dx - halfTop * 0.05 + lean * s * 0.1,
          topY,
        )
        ..lineTo(base.dx - halfTop + lean * s * 0.15, topY)
        ..quadraticBezierTo(base.dx - halfMid, midY, base.dx - halfBot * 1.15, base.dy + 0.4 * s)
        ..close(),
      _fill,
    );

    // Right moon-kissed bark.
    _fill.color = Color.lerp(_trunkLite, _moon, 0.14)!.withValues(alpha: 0.5);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + halfBot * 0.05, base.dy)
        ..quadraticBezierTo(base.dx + halfBot * 0.4, lowY, base.dx + halfMid * 0.35, midY)
        ..quadraticBezierTo(
          base.dx + halfTop * 0.3,
          topY + 3 * s,
          base.dx + halfTop * 0.35 + lean * s * 0.3,
          topY,
        )
        ..lineTo(base.dx + halfTop + lean * s * 0.4, topY)
        ..quadraticBezierTo(base.dx + halfMid * 0.85, midY, base.dx + halfBot * 0.95, base.dy)
        ..close(),
      _fill,
    );

    // Subtle bark strokes.
    _stroke
      ..color = _trunkDeep.withValues(alpha: 0.35)
      ..strokeWidth = 1.0 * s;
    canvas.drawLine(
      Offset(base.dx - tw * 0.15, base.dy - 2 * s),
      Offset(base.dx - tw * 0.05 + lean * s * 0.2, topY + 4 * s),
      _stroke,
    );
    canvas.drawLine(
      Offset(base.dx + tw * 0.2, base.dy - 3 * s),
      Offset(base.dx + tw * 0.25 + lean * s * 0.25, topY + 6 * s),
      _stroke,
    );

    // Root toes.
    _fill.color = _trunkDeep;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - tw * 0.3, base.dy - 1.5 * s)
        ..quadraticBezierTo(base.dx - tw * 1.0, base.dy, base.dx - tw * 1.3, base.dy + 1.5 * s)
        ..quadraticBezierTo(base.dx - tw * 0.55, base.dy + 2.4 * s, base.dx - tw * 0.15, base.dy + 0.6 * s)
        ..close(),
      _fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + tw * 0.2, base.dy - 1.2 * s)
        ..quadraticBezierTo(base.dx + tw * 0.9, base.dy, base.dx + tw * 1.15, base.dy + 1.3 * s)
        ..quadraticBezierTo(base.dx + tw * 0.5, base.dy + 2.1 * s, base.dx + tw * 0.1, base.dy + 0.5 * s)
        ..close(),
      _fill,
    );

    // Primary Y branches into the canopy.
    final fork = Offset(base.dx + lean * s * 0.25, topY + 1.5 * s);
    _taperLimb(canvas, fork, fork + Offset(-tw * 1.25, -11 * s), 3.8 * s, 1.7 * s, lit: false);
    _taperLimb(
      canvas,
      fork + Offset(-tw * 0.5, -4 * s),
      fork + Offset(-tw * 1.7, -16 * s),
      2.2 * s,
      1.0 * s,
      lit: false,
    );
    _taperLimb(canvas, fork, fork + Offset(tw * 1.35, -12 * s), 4.0 * s, 1.8 * s, lit: true);
    _taperLimb(
      canvas,
      fork + Offset(tw * 0.55, -4.5 * s),
      fork + Offset(tw * 1.85, -17 * s),
      2.3 * s,
      1.05 * s,
      lit: true,
    );
    _taperLimb(
      canvas,
      fork + Offset(0.2 * s, -0.5 * s),
      fork + Offset(1.0 * s, -14 * s),
      2.7 * s,
      1.15 * s,
      lit: true,
    );
  }

  static void _branchTips(Canvas canvas, Offset crown, double tw, double s) {
    final fork = Offset(crown.dx + 0.4 * s, crown.dy + 1.5 * s);
    // Tips in the scooped hollow — partially covered by canopy belly.
    _taperLimb(
      canvas,
      Offset.lerp(fork, fork + Offset(-tw * 1.25, -11 * s), 0.5)!,
      fork + Offset(-tw * 1.25, -11 * s),
      2.0 * s,
      1.4 * s,
      lit: false,
    );
    _taperLimb(
      canvas,
      Offset.lerp(fork, fork + Offset(tw * 1.35, -12 * s), 0.5)!,
      fork + Offset(tw * 1.35, -12 * s),
      2.1 * s,
      1.5 * s,
      lit: true,
    );
    _taperLimb(
      canvas,
      Offset.lerp(fork, fork + Offset(1.0 * s, -14 * s), 0.45)!,
      fork + Offset(1.0 * s, -14 * s),
      1.7 * s,
      1.1 * s,
      lit: true,
    );
  }

  static void _taperLimb(
    Canvas canvas,
    Offset a,
    Offset b,
    double thickStart,
    double thickEnd, {
    required bool lit,
  }) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 0.5) return;
    final px = -dy / len;
    final py = dx / len;

    final path = Path()
      ..moveTo(a.dx + px * thickStart * 0.5, a.dy + py * thickStart * 0.5)
      ..lineTo(b.dx + px * thickEnd * 0.5, b.dy + py * thickEnd * 0.5)
      ..lineTo(b.dx - px * thickEnd * 0.5, b.dy - py * thickEnd * 0.5)
      ..lineTo(a.dx - px * thickStart * 0.5, a.dy - py * thickStart * 0.5)
      ..close();

    _fill.color = lit ? _trunkMid : _trunkDeep;
    canvas.drawPath(path, _fill);

    if (lit) {
      _fill.color = _trunkLite.withValues(alpha: 0.4);
      canvas.drawPath(
        Path()
          ..moveTo(a.dx + px * thickStart * 0.15, a.dy + py * thickStart * 0.15)
          ..lineTo(b.dx + px * thickEnd * 0.15, b.dy + py * thickEnd * 0.15)
          ..lineTo(b.dx - px * thickEnd * 0.05, b.dy - py * thickEnd * 0.05)
          ..lineTo(a.dx - px * thickStart * 0.05, a.dy - py * thickStart * 0.05)
          ..close(),
        _fill,
      );
    }
  }

  // ── Grounding ──

  static void _groundContact(Canvas canvas, Offset c, double tw, double cw, double s) {
    _fill.color = const Color(0x2A0A1018);
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(-3 * s, 2.5 * s),
        width: cw * 0.5 + 10 * s,
        height: 10 * s,
      ),
      _fill,
    );
    _fill.color = const Color(0x22081018);
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, 2 * s), width: tw * 2.5, height: 7 * s),
      _fill,
    );
  }

  static void _understory(Canvas canvas, Offset c, double tw, double s) {
    final w = tw * 2.9;
    _fill.color = const Color(0x33101814);
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, 1.4 * s), width: w * 1.15, height: 7 * s),
      _fill,
    );
    _fill.color = _moss;
    canvas.drawOval(Rect.fromCenter(center: c, width: w, height: 6 * s), _fill);
    _fill.color = _mossLite;
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(w * 0.12, -1.2 * s), width: w * 0.45, height: 3.2 * s),
      _fill,
    );
    // Side tufts tuck the trunk into the meadow (small, not canopy).
    _fill.color = _shade(_body, 0, cool: 0.12);
    canvas.drawPath(_mass(c + Offset(-tw * 1.15, -1 * s), 8.5 * s, 5.5 * s), _fill);
    canvas.drawPath(_mass(c + Offset(tw * 1.1, -0.5 * s), 7.5 * s, 5 * s), _fill);
  }

  static void _frontPlanting(Canvas canvas, Offset c, double tw, double s) {
    _stroke
      ..color = const Color(0xFF2A6848)
      ..strokeWidth = 1.35 * s;
    void blade(double x, double h, double lean) {
      canvas.drawLine(
        Offset(c.dx + x, c.dy + 1.2 * s),
        Offset(c.dx + x + lean, c.dy - h),
        _stroke,
      );
    }

    blade(-tw * 0.9, 5.5 * s, -1.2 * s);
    blade(-tw * 0.45, 6.5 * s, -0.3 * s);
    blade(tw * 0.15, 5.8 * s, 0.8 * s);
    blade(tw * 0.7, 5.0 * s, 1.4 * s);
  }

  static Color _shade(Color base, double darken, {double cool = 0, double warm = 0}) {
    var c = base;
    if (cool > 0) c = Color.lerp(c, _night, cool.clamp(0.0, 0.5))!;
    if (warm > 0) c = Color.lerp(c, _moon, warm.clamp(0.0, 0.35))!;
    if (darken > 0) c = Color.lerp(c, _night, darken)!;
    return c;
  }
}
