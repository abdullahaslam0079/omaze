import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/render/render_context.dart';

/// Painterly wildflowers with stem sway and a few bloom types.
class BloomRenderer {
  const BloomRenderer._();

  static void draw(Canvas canvas, int lane, int z, HopRenderContext ctx) {
    final seed = lane * 17 + z * 31;
    final kind = seed % 4;
    final sc = 0.88 + (seed % 9) * 0.04;
    final p = ctx.tilePos(lane + 0.28 + (seed % 5) * 0.04, z + 0.52 + (seed % 3) * 0.04);
    final sway = ctx.wind(lane.toDouble(), z.toDouble(), amp: 1.15);
    final head = Offset(p.dx + sway, p.dy - 14 * sc);

    canvas.drawOval(
      Rect.fromCenter(center: p + const Offset(1, 7), width: 10 * sc, height: 4 * sc),
      Paint()..color = const Color(0x28000000),
    );

    final stem = Path()
      ..moveTo(p.dx, p.dy + 6 * sc)
      ..quadraticBezierTo(
        p.dx + sway * 0.35,
        p.dy - 4 * sc,
        head.dx,
        head.dy + 3 * sc,
      );
    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xFF2A6A32)
        ..strokeWidth = 1.7 * sc
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    _leaf(canvas, Offset(p.dx + sway * 0.2, p.dy - 1 * sc), sc, sway * 0.4, seed.isEven);

    switch (kind) {
      case 0:
        _daisy(canvas, head, sc, sway);
      case 1:
        _rose(canvas, head, sc, sway);
      case 2:
        _cluster(canvas, head, sc, sway, ctx.time + lane);
      default:
        _poppy(canvas, head, sc, sway);
    }
  }

  static void _leaf(Canvas canvas, Offset p, double sc, double lean, bool left) {
    final dir = left ? -1.0 : 1.0;
    final tip = Offset(p.dx + dir * 8 * sc + lean, p.dy - 3 * sc);
    final path = Path()
      ..moveTo(p.dx, p.dy)
      ..quadraticBezierTo(p.dx + dir * 4 * sc, p.dy - 5 * sc, tip.dx, tip.dy)
      ..quadraticBezierTo(p.dx + dir * 3 * sc, p.dy + 1 * sc, p.dx, p.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xAA3C8A40));
  }

  static void _daisy(Canvas canvas, Offset c, double sc, double sway) {
    const petal = Color(0xFFF7F1E4);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + sway * 0.04;
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(math.cos(a) * 5.2 * sc, math.sin(a) * 4.4 * sc),
          width: 5.2 * sc,
          height: 3.4 * sc,
        ),
        Paint()..color = petal,
      );
    }
    canvas.drawCircle(c, 2.6 * sc, Paint()..color = const Color(0xFFF0C45A));
    canvas.drawCircle(c + Offset(-0.6 * sc, -0.7 * sc), 1.0 * sc, Paint()..color = const Color(0x66FFFFFF));
  }

  static void _rose(Canvas canvas, Offset c, double sc, double sway) {
    const petal = Color(0xFFE85D8A);
    for (var i = 0; i < 5; i++) {
      final a = i * 1.256 + 0.2 + sway * 0.03;
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(math.cos(a) * 4.0 * sc, math.sin(a) * 3.4 * sc - 0.4 * sc),
          width: 5.4 * sc,
          height: 4.2 * sc,
        ),
        Paint()..color = petal,
      );
    }
    canvas.drawCircle(c, 2.2 * sc, Paint()..color = const Color(0xFFFFF1B0));
    canvas.drawCircle(c + Offset(-0.5 * sc, -0.6 * sc), 0.9 * sc, Paint()..color = const Color(0x66FFFFFF));
  }

  static void _cluster(Canvas canvas, Offset c, double sc, double sway, double phase) {
    const colors = [Color(0xFF7A8EE8), Color(0xFFB07AE8), Color(0xFF6AD0E8)];
    for (var i = 0; i < 6; i++) {
      final a = i * 1.05 + 0.4;
      final bob = math.sin(phase * 1.6 + i) * 0.6;
      final pos = c + Offset(math.cos(a) * 5.5 * sc + sway * 0.15, math.sin(a) * 3.8 * sc + bob);
      canvas.drawCircle(pos, 2.3 * sc, Paint()..color = colors[i % colors.length]);
      canvas.drawCircle(pos + Offset(-0.5 * sc, -0.5 * sc), 0.7 * sc, Paint()..color = const Color(0x55FFFFFF));
    }
  }

  static void _poppy(Canvas canvas, Offset c, double sc, double sway) {
    const petal = Color(0xFFE07038);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + 0.4 + sway * 0.03;
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(math.cos(a) * 3.6 * sc, math.sin(a) * 3.0 * sc - 0.6 * sc),
          width: 6.4 * sc,
          height: 4.8 * sc,
        ),
        Paint()..color = petal,
      );
    }
    canvas.drawCircle(c, 1.8 * sc, Paint()..color = const Color(0xFF2A1A18));
    canvas.drawCircle(c + Offset(-0.4 * sc, -0.5 * sc), 0.7 * sc, Paint()..color = const Color(0x44FFFFFF));
  }
}
