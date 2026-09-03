import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/domain/domain.dart';
import 'package:omaze/game/hop/render/render_context.dart';

/// Draws the enchanted river rows (water, current, floaters, reeds).
class RiverRenderer {
  const RiverRenderer._();

  static void draw(Canvas canvas, HopRow row, Rect rect, Offset origin, HopRenderContext ctx) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, origin.dy - ctx.tile),
          Offset(0, origin.dy),
          const [Color(0xFF1A6E86), Color(0xFF0C3E62), Color(0xFF082838)],
          const [0.0, 0.45, 1.0],
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(ctx.size.width * 0.5, origin.dy - ctx.tile * 0.42),
        width: ctx.size.width * 0.9,
        height: ctx.tile * 0.34,
      ),
      Paint()..color = const Color(0x3328C0D8),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, origin.dy - ctx.tile, ctx.size.width, 5),
      Paint()..color = const Color(0x66D8F4FF),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, origin.dy - 6, ctx.size.width, 6),
      Paint()..color = const Color(0x4480C0D0),
    );

    final flow = row.dir * math.max(row.speed, 0.28);
    final drift = ctx.time * ctx.tile * flow;
    _drawCurrent(canvas, row, origin, drift, ctx);
    for (final log in row.movers) {
      _drawFloaterWake(canvas, row, log, ctx);
    }
    for (final log in row.movers) {
      _drawFloater(canvas, row, log, ctx);
    }
    _drawReeds(canvas, row, ctx);
  }

  static void drawRideRipple(Canvas canvas, Offset p, HopRow row, HopRenderContext ctx) {
    final pulse = 0.55 + 0.45 * ((math.sin(ctx.time * 6) + 1) / 2);
    canvas.drawOval(
      Rect.fromCenter(center: p + const Offset(0, 12), width: 28 + pulse * 6, height: 8),
      Paint()..color = Color.fromRGBO(200, 244, 255, 0.18 + 0.1 * pulse),
    );
    canvas.drawLine(
      p + Offset(-row.dir * 6, 11),
      p + Offset(-row.dir * 18, 12),
      Paint()
        ..color = const Color(0x55E8FFFF)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  static double _cycle(double value, double span) {
    final m = value % span;
    return m < 0 ? m + span : m;
  }

  static double floaterBob(double x, int z, double time) {
    return math.sin(time * 3.2 + x * 1.4 + z) * 2.4;
  }

  static void _drawCurrent(Canvas canvas, HopRow row, Offset origin, double drift, HopRenderContext ctx) {
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var band = 0; band < 5; band++) {
      final y = origin.dy - ctx.tile * (0.16 + band * 0.15);
      final path = Path()..moveTo(-16, y);
      for (var x = 0.0; x <= ctx.size.width + 20; x += 8) {
        path.lineTo(
          x,
          y + math.sin(ctx.time * 1.6 + (x - drift) * 0.075 + row.index + band) * (4.2 + band * 0.55),
        );
      }
      wavePaint
        ..color = band.isEven ? const Color(0x77D0F6FF) : const Color(0x5588D8EC)
        ..strokeWidth = band == 0 ? 2.6 : 1.7;
      canvas.drawPath(path, wavePaint);
    }

    final streak = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 12; i++) {
      final y = origin.dy - ctx.tile * (0.18 + (i % 5) * 0.14);
      final span = ctx.size.width + 50;
      final x = _cycle(i * 54.0 + row.index * 19 + drift * (1.05 + (i % 3) * 0.12), span) - 24;
      final len = 18.0 + (i % 4) * 9;
      streak
        ..color = Color.fromRGBO(210, 246, 255, 0.16 + (i % 3) * 0.05)
        ..strokeWidth = 1.5 + (i % 2) * 0.5;
      canvas.drawLine(Offset(x, y), Offset(x + row.dir * len, y), streak);
    }

    for (var i = 0; i < 7; i++) {
      final y = origin.dy - ctx.tile * (0.24 + (i % 4) * 0.14);
      final span = ctx.size.width + 36;
      final x = _cycle(i * 68.0 + row.index * 11 + drift * 1.2, span) - 8;
      final chev = Path()
        ..moveTo(x, y - 3.2)
        ..lineTo(x + row.dir * 8, y)
        ..lineTo(x, y + 3.2);
      canvas.drawPath(
        chev,
        Paint()
          ..color = const Color(0x55E8FFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var i = 0; i < 8; i++) {
      final span = ctx.size.width + 30;
      final x = _cycle(i * 76.0 + row.index * 13 + drift * 1.15, span) - 10;
      final y = origin.dy - ctx.tile * (0.26 + (i % 3) * 0.18);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 26, height: 6),
        Paint()..color = const Color(0x3388E8FF),
      );
    }
    for (var i = 0; i < 8; i++) {
      final span = ctx.size.width + 16;
      final x = _cycle(i * 64.0 + row.index * 9 + drift * 0.9, span);
      final twinkle = 0.35 + 0.65 * ((math.sin(ctx.time * 5 + i) + 1) / 2);
      canvas.drawCircle(
        Offset(x, origin.dy - ctx.tile * (0.32 + (i % 4) * 0.12)),
        1.4,
        Paint()..color = Color.fromRGBO(255, 255, 255, 0.58 * twinkle),
      );
    }
  }

  static void _drawFloaterWake(Canvas canvas, HopRow row, Mover log, HopRenderContext ctx) {
    final bob = floaterBob(log.x, row.index, ctx.time);
    final p = ctx.tilePos(log.x, row.index + 0.18) + Offset(0, bob);
    final w = log.w * ctx.tile;
    final stern = p.dx + (row.dir > 0 ? 0 : w);
    for (var i = 1; i <= 5; i++) {
      final t = i / 5;
      final x = stern - row.dir * (12.0 + i * 13);
      final y = p.dy + 5 + math.sin(ctx.time * 7 + log.x + i) * 1.8;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 16 + (1 - t) * 10, height: 5 + (1 - t) * 2),
        Paint()..color = Color.fromRGBO(220, 248, 255, 0.22 * (1 - t)),
      );
    }
    final bow = p.dx + (row.dir > 0 ? w : 0);
    ctx.glow(canvas, Offset(bow + row.dir * 6, p.dy + 2), 10, const Color(0x3348E0C8));
  }

  static void _drawReeds(Canvas canvas, HopRow row, HopRenderContext ctx) {
    for (final lane in [-1.0, WorldGenerator.lanes.toDouble()]) {
      final base = ctx.tilePos(lane + 0.35, row.index + 0.55);
      final sway = math.sin(ctx.time * 1.6 + lane + row.index) * 2.4;
      for (var i = 0; i < 4; i++) {
        final path = Path()
          ..moveTo(base.dx + i * 5, base.dy + 6)
          ..quadraticBezierTo(
            base.dx + i * 5 + sway,
            base.dy - 8,
            base.dx + i * 5 + sway * 1.4,
            base.dy - 16 - i * 2,
          );
        canvas.drawPath(
          path,
          Paint()
            ..color = i.isEven ? const Color(0xAA2A6834) : const Color(0xCC1C4A22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  static void _drawFloater(Canvas canvas, HopRow row, Mover log, HopRenderContext ctx) {
    final p = ctx.tilePos(log.x, row.index + 0.18) + Offset(0, floaterBob(log.x, row.index, ctx.time));
    if (row.pads) {
      final c = Offset(p.dx + log.w * ctx.tile / 2, p.dy - ctx.tile * 0.14);
      final w = log.w * ctx.tile;
      final h = ctx.tile * 0.40;
      canvas.drawOval(
        Rect.fromCenter(center: c + const Offset(0, 6), width: w, height: h),
        Paint()..color = const Color(0x44000000),
      );
      final pad = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + 11, c.dy - 3)
        ..arcTo(Rect.fromCenter(center: c, width: w, height: h), -0.25, math.pi * 2 - 0.7, false)
        ..close();
      canvas.drawPath(pad, Paint()..color = const Color(0xFF2F9A44));
      canvas.drawPath(pad, Paint()..color = const Color(0xFF1E6A30)..style = PaintingStyle.stroke..strokeWidth = 1.4);
      final vein = Paint()..color = const Color(0x66206030)..strokeWidth = 1;
      for (var i = 0; i < 4; i++) {
        final a = -0.4 + i * 0.7;
        canvas.drawLine(c, c + Offset(math.cos(a) * w * 0.32, math.sin(a) * h * 0.28), vein);
      }
      canvas.drawOval(
        Rect.fromCenter(center: c + const Offset(-6, -3), width: w * 0.28, height: h * 0.28),
        Paint()..color = const Color(0x5538C858),
      );
      ctx.glow(canvas, c, 9, const Color(0x3348E0C8));
      canvas.drawCircle(c + const Offset(7, -5), 3.2, Paint()..color = const Color(0xFFE85D8A));
      canvas.drawCircle(c + const Offset(7, -5), 1.3, Paint()..color = const Color(0xFFFFF1B0));
      return;
    }

    final w = log.w * ctx.tile;
    final h = ctx.tile * 0.50;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(p.dx, p.dy - h * 0.72, w, h),
      const Radius.circular(18),
    );
    canvas.drawRRect(body.shift(const Offset(0, 6)), Paint()..color = const Color(0x55000000));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF7A4A22));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(p.dx + 8, p.dy - h * 0.62, w - 16, h * 0.22), const Radius.circular(10)),
      Paint()..color = const Color(0x66D2A06A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(p.dx + 14, p.dy - h * 0.18, 22, 8), const Radius.circular(4)),
      Paint()..color = const Color(0x66489038),
    );
    canvas.drawCircle(Offset(p.dx + 12, p.dy - h * 0.22), 8, Paint()..color = const Color(0xFF5A3418));
    canvas.drawCircle(
      Offset(p.dx + 12, p.dy - h * 0.22),
      5,
      Paint()..color = const Color(0x66402010)..style = PaintingStyle.stroke..strokeWidth = 1.6,
    );
    canvas.drawCircle(Offset(p.dx + w - 12, p.dy - h * 0.22), 8, Paint()..color = const Color(0xFF5A3418));
    canvas.drawCircle(Offset(p.dx + 28, p.dy - h * 0.38), 2.6, Paint()..color = const Color(0xFFD24B4B));
    canvas.drawCircle(Offset(p.dx + 28, p.dy - h * 0.40), 0.9, Paint()..color = const Color(0xFFF7E8D0));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(p.dx + 6, p.dy - 4, w - 12, 3), const Radius.circular(2)),
      Paint()..color = const Color(0x44A8E8FF),
    );
  }
}
