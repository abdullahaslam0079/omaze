import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/domain/domain.dart';
import 'package:omaze/game/hop/render/render_context.dart';

/// Draws the rune-rail rows and trains.
class RailRenderer {
  const RailRenderer._();

  static void draw(Canvas canvas, HopRow row, Rect rect, Offset origin, HopRenderContext ctx) {
    drawTrack(canvas, row, rect, origin, ctx);
    for (final train in row.movers) {
      _drawTrain(canvas, row, train, ctx);
    }
  }

  static void drawTrack(Canvas canvas, HopRow row, Rect rect, Offset origin, HopRenderContext ctx) {
    canvas.drawRect(rect, Paint()..color = const Color(0xFF3A2A28));
    final sleeper = Paint()..color = const Color(0xFF6A4A2E);
    for (var i = 0; i < 12; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 36.0 + 4, origin.dy - ctx.tile * 0.78, 18, ctx.tile * 0.56),
          const Radius.circular(2),
        ),
        sleeper,
      );
    }
    final steel = Paint()
      ..color = const Color(0xFFE8C36A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, origin.dy - ctx.tile * 0.68), Offset(ctx.size.width, origin.dy - ctx.tile * 0.68), steel);
    canvas.drawLine(Offset(0, origin.dy - ctx.tile * 0.32), Offset(ctx.size.width, origin.dy - ctx.tile * 0.32), steel);
    final pulse = 0.45 + 0.55 * ((math.sin(ctx.time * 6) + 1) / 2);
    final light = Paint()..color = Color.fromRGBO(255, 80, 70, 0.45 + 0.55 * pulse);
    ctx.glow(canvas, Offset(16, origin.dy - ctx.tile * 0.5), 10, Color.fromRGBO(255, 60, 50, 0.35 * pulse));
    canvas.drawCircle(Offset(16, origin.dy - ctx.tile * 0.5), 5, light);
    canvas.drawCircle(Offset(ctx.size.width - 16, origin.dy - ctx.tile * 0.5), 5, light);
  }

  static void _drawTrain(Canvas canvas, HopRow row, Mover train, HopRenderContext ctx) {
    final p = ctx.tilePos(train.x, row.index + 0.18);
    final w = train.w * ctx.tile;
    final h = ctx.tile * 0.72;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(p.dx, p.dy - h + 6, w, h), const Radius.circular(6)),
      Paint()..color = const Color(0x66000000),
    );
    var x = p.dx;
    var first = true;
    while (x < p.dx + w - 8) {
      final cw = first ? ctx.tile * 1.15 : ctx.tile * 0.95;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, p.dy - h, cw - 6, h), const Radius.circular(6)),
        Paint()..color = first ? const Color(0xFFC43B4A) : const Color(0xFF2A2438),
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 8, p.dy - h + 10, cw - 22, 11),
        Paint()..color = first ? const Color(0x66F4C542) : const Color(0xAA111318),
      );
      if (first) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x + cw - 22, p.dy - h - 10, 8, 12), const Radius.circular(2)),
          Paint()..color = const Color(0xFF3A2A28),
        );
        ctx.glow(canvas, Offset(x + cw - 18, p.dy - h - 12), 8, const Color(0x66F4C542));
        canvas.drawCircle(Offset(x + 14, p.dy - 12), 3, Paint()..color = const Color(0xFFFFF1B0));
      }
      x += cw;
      first = false;
    }
  }
}
