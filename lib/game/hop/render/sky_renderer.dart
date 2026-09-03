import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/render/render_context.dart';

/// Draws the background sky, stars, aurora, moons, clouds, and mountains.
class SkyRenderer {
  const SkyRenderer._();

  static void draw(Canvas canvas, HopRenderContext ctx) {
    final h = ctx.size.height;
    final w = ctx.size.width;

    canvas.drawRect(
      Offset.zero & Size(w, h),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, ctx.horizon + 36),
          const [
            Color(0xFF0E0A24),
            Color(0xFF1C1440),
            Color(0xFF3A2468),
            Color(0xFF6A3A78),
            Color(0xFFB07070),
            Color(0xFFE8B878),
          ],
          const [0.0, 0.22, 0.48, 0.72, 0.88, 1.0],
        ),
    );

    // Soft night wash just under the horizon seam (backdrop only).
    canvas.drawRect(
      Rect.fromLTWH(0, ctx.horizon - 8, w, 28),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, ctx.horizon - 8),
          Offset(0, ctx.horizon + 20),
          const [
            Color(0xFF1A1238),
            Color(0x88181030),
            Color(0x00101820),
          ],
          const [0.0, 0.45, 1.0],
        ),
    );

    _drawStars(canvas, ctx);
    _drawAurora(canvas, ctx);
    _drawMoons(canvas, ctx);
    _drawClouds(canvas, ctx);
    _drawMountains(canvas, ctx);
    _drawFoothills(canvas, ctx);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.16),
          w * 0.95,
          [const Color(0x00000000), const Color(0x3308141C)],
        ),
    );
  }

  /// Thin seam mist — only at the mountain line, never over playable lanes.
  static void drawHorizonMist(Canvas canvas, HopRenderContext ctx) {
    final w = ctx.size.width;
    final y = ctx.horizon;

    // Soft tuck under the foothills (very short).
    canvas.drawRect(
      Rect.fromLTWH(0, y - 8, w, 22),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, y - 8),
          Offset(0, y + 14),
          const [
            Color(0x00141028),
            Color(0x44181030),
            Color(0x28C8A878),
            Color(0x00000000),
          ],
          const [0.0, 0.35, 0.65, 1.0],
        ),
    );

    // Warm moonlight kiss on the ridge only.
    canvas.drawRect(
      Rect.fromLTWH(0, y - 16, w, 28),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, y - 16),
          Offset(0, y + 12),
          const [
            Color(0x00F8E0B0),
            Color(0x33F3C27A),
            Color(0x00F3C27A),
          ],
          const [0.0, 0.45, 1.0],
        ),
    );
  }

  /// Soft edge only for the last half-tile under the mountains.
  static ui.Gradient playfieldFade(HopRenderContext ctx) {
    return ui.Gradient.linear(
      Offset(0, ctx.horizon - 4),
      Offset(0, ctx.horizon + ctx.tile * 0.55),
      const [
        Color(0x00FFFFFF),
        Color(0x88FFFFFF),
        Color(0xFFFFFFFF),
      ],
      const [0.0, 0.45, 1.0],
    );
  }

  static void drawFireflies(Canvas canvas, HopRenderContext ctx) {
    // Keep sparkles in the sky / near the ridge — not over the playfield.
    for (var i = 0; i < 10; i++) {
      final x = (math.sin(ctx.time * 0.55 + i * 1.7) * 0.46 + 0.5) * ctx.size.width;
      final y = ctx.horizon - 70 + (math.cos(ctx.time * 0.42 + i * 2.2) * 0.5 + 0.5) * 58;
      if (y > ctx.horizon + 8) continue;
      final pulse = 0.2 + 0.55 * ((math.sin(ctx.time * 3.4 + i * 1.3) + 1) / 2);
      final c = Offset(x, y);
      ctx.glow(canvas, c, 5, Color.fromRGBO(255, 220, 120, 0.12 * pulse));
      canvas.drawCircle(c, 1.3, Paint()..color = Color.fromRGBO(255, 236, 170, pulse * 0.85));
    }
  }

  // ── Private helpers ──

  static void _drawStars(Canvas canvas, HopRenderContext ctx) {
    final paint = Paint();
    final maxY = ctx.horizon - 24;
    for (var i = 0; i < 46; i++) {
      final seed = i * 97.0;
      final x = (seed * 13.7) % ctx.size.width;
      final y = 18 + (seed * 7.3) % math.max(40.0, maxY - 18);
      if (y > maxY) continue;
      final twinkle = 0.35 + 0.65 * ((math.sin(ctx.time * 2.1 + i) + 1) / 2);
      final r = 0.7 + (i % 4) * 0.45;
      paint.color = Color.fromRGBO(255, 236, 196, (0.55 * twinkle).clamp(0, 1));
      canvas.drawCircle(Offset(x, y), r, paint);
      if (i % 7 == 0) {
        ctx.glow(canvas, Offset(x, y), 5, Color.fromRGBO(255, 220, 160, 0.16 * twinkle));
      }
    }
  }

  static void _drawAurora(Canvas canvas, HopRenderContext ctx) {
    for (var band = 0; band < 3; band++) {
      final path = Path();
      final y0 = 70.0 + band * 28;
      if (y0 > ctx.horizon - 20) continue;
      path.moveTo(-20, y0);
      for (var x = 0.0; x <= ctx.size.width + 20; x += 18) {
        final y = y0 +
            math.sin(ctx.time * 0.45 + x * 0.018 + band) * 16 +
            math.sin(ctx.time * 0.7 + x * 0.04 + band * 2) * 8;
        path.lineTo(x, y);
      }
      path.lineTo(ctx.size.width + 20, y0 + 40);
      path.lineTo(-20, y0 + 40);
      path.close();
      final colors = [
        const Color(0x3348E0C8),
        const Color(0x289B6CFF),
        const Color(0x22F0A0E0),
      ];
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, y0 - 10),
            Offset(0, y0 + 36),
            [colors[band], colors[band].withValues(alpha: 0)],
          ),
      );
    }
  }

  static void _drawMoons(Canvas canvas, HopRenderContext ctx) {
    final big = Offset(ctx.size.width * 0.78, math.min(92.0, ctx.horizon - 48));
    ctx.glow(canvas, big, 46, const Color(0x55FFE6B0));
    canvas.drawCircle(big, 26, Paint()..color = const Color(0xFFF8E8C4));
    canvas.drawCircle(big + const Offset(-7, -4), 8, Paint()..color = const Color(0x22C9B48A));
    canvas.drawCircle(big + const Offset(8, 6), 5, Paint()..color = const Color(0x18A89068));
    canvas.drawCircle(big + const Offset(4, -10), 3.5, Paint()..color = const Color(0x14FFFFFF));

    final small = Offset(ctx.size.width * 0.22, math.min(64.0, ctx.horizon - 60));
    ctx.glow(canvas, small, 22, const Color(0x44F0B8D8));
    canvas.drawCircle(small, 11, Paint()..color = const Color(0xFFF2C4D8));
    canvas.drawCircle(small + const Offset(-3, 2), 3, Paint()..color = const Color(0x22A07088));
  }

  static void _drawClouds(Canvas canvas, HopRenderContext ctx) {
    final paint = Paint()..color = const Color(0x33F4E4FF);
    for (var i = 0; i < 5; i++) {
      final x = ((ctx.time * 8 + i * 150) % (ctx.size.width + 160)) - 80;
      final y = 56.0 + i * 22;
      if (y > ctx.horizon - 30) continue;
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 110, height: 26), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 28, y - 10), width: 64, height: 22), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 22, y - 6), width: 50, height: 18), paint);
    }
  }

  static void _drawMountains(Canvas canvas, HopRenderContext ctx) {
    final y = ctx.horizon;
    final w = ctx.size.width;

    void ridge(List<Offset> pts, Color color, {double fadeBelow = 12}) {
      final path = Path()..moveTo(-4, y + fadeBelow);
      path.lineTo(-4, pts.first.dy);
      for (final p in pts) {
        path.lineTo(p.dx, p.dy);
      }
      path.lineTo(w + 4, pts.last.dy);
      path.lineTo(w + 4, y + fadeBelow);
      path.close();
      canvas.drawPath(path, Paint()..color = color);

      canvas.drawRect(
        Rect.fromLTWH(0, y, w, fadeBelow + 4),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, y),
            Offset(0, y + fadeBelow + 4),
            [color, color.withValues(alpha: 0)],
          ),
      );
    }

    ridge([
      Offset(0, y - 8),
      Offset(w * 0.14, y - 52),
      Offset(w * 0.28, y - 20),
      Offset(w * 0.46, y - 78),
      Offset(w * 0.62, y - 24),
      Offset(w * 0.78, y - 58),
      Offset(w, y - 14),
    ], const Color(0xFF2A1848), fadeBelow: 10);

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.42, y - 74)
        ..lineTo(w * 0.46, y - 78)
        ..lineTo(w * 0.5, y - 62)
        ..close(),
      Paint()..color = const Color(0x28F8E8C4),
    );

    ridge([
      Offset(0, y + 2),
      Offset(w * 0.18, y - 26),
      Offset(w * 0.38, y + 1),
      Offset(w * 0.66, y - 32),
      Offset(w, y + 2),
    ], const Color(0xFF1C1238), fadeBelow: 8);

    final keepX = w * 0.44;
    final keepY = y - 76;
    canvas.drawRect(Rect.fromLTWH(keepX, keepY, 16, 28), Paint()..color = const Color(0xFF24143A));
    canvas.drawRect(Rect.fromLTWH(keepX + 17, keepY + 8, 12, 20), Paint()..color = const Color(0xFF24143A));
    canvas.drawRect(Rect.fromLTWH(keepX - 8, keepY + 12, 8, 16), Paint()..color = const Color(0xFF24143A));
    final spire = Path()
      ..moveTo(keepX - 2, keepY)
      ..lineTo(keepX + 8, keepY - 18)
      ..lineTo(keepX + 18, keepY)
      ..close();
    canvas.drawPath(spire, Paint()..color = const Color(0xFF2E1848));
    ctx.glow(canvas, Offset(keepX + 8, keepY + 10), 11, const Color(0x55F4C542));
    canvas.drawCircle(Offset(keepX + 8, keepY + 12), 2.2, Paint()..color = const Color(0xAAF4C542));
  }

  static void _drawFoothills(Canvas canvas, HopRenderContext ctx) {
    final y = ctx.horizon;
    final w = ctx.size.width;

    // Near ridge sitting on the horizon — does not spill into play lanes.
    final hills = Path()
      ..moveTo(-10, y + 6)
      ..lineTo(-10, y);
    for (var x = 0.0; x <= w + 20; x += 24) {
      final hump = math.sin(x * 0.048 + 0.6) * 8 + math.sin(x * 0.11) * 3.5;
      hills.lineTo(x, y - 1 - hump);
    }
    hills
      ..lineTo(w + 10, y + 6)
      ..close();
    canvas.drawPath(hills, Paint()..color = const Color(0xFF161028));

    // Distant tree silhouettes along the ridge only.
    for (var i = 0; i < 24; i++) {
      final x = -8.0 + i * (w / 21.5) + (i % 3) * 4;
      final tall = 11.0 + (i * 17 % 12);
      final kind = i % 3;
      final base = Offset(x, y + 2);
      final alpha = (190 - (i % 5) * 14).clamp(100, 190);
      final paint = Paint()..color = Color.fromARGB(alpha, 12, 8, 28);

      if (kind == 0) {
        final pine = Path()
          ..moveTo(base.dx, base.dy - tall)
          ..lineTo(base.dx - 5, base.dy)
          ..lineTo(base.dx + 5, base.dy)
          ..close();
        canvas.drawPath(pine, paint);
      } else if (kind == 1) {
        canvas.drawOval(
          Rect.fromCenter(center: base + Offset(0, -tall * 0.35), width: 12 + (i % 3), height: tall * 0.65),
          paint,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: base + Offset(-2.5, -tall * 0.28), width: 8, height: tall * 0.45),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: base + Offset(3.5, -tall * 0.32), width: 7, height: tall * 0.4),
          paint,
        );
      }
    }

    // Soft base so the ridge meets the first play lane cleanly.
    canvas.drawRect(
      Rect.fromLTWH(0, y - 2, w, 14),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, y - 2),
          Offset(0, y + 12),
          const [Color(0x55141028), Color(0x00000000)],
        ),
    );
  }
}
