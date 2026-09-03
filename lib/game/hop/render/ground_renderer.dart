import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/domain/domain.dart';
import 'package:omaze/game/hop/render/bloom_renderer.dart';
import 'package:omaze/game/hop/render/crystal_renderer.dart';
import 'package:omaze/game/hop/render/render_context.dart';
import 'package:omaze/game/hop/render/rock_renderer.dart';
import 'package:omaze/game/hop/render/shroom_renderer.dart';
import 'package:omaze/game/hop/render/tree_renderer.dart';
import 'package:omaze/game/hop/render/vehicle_renderer.dart';
import 'package:omaze/game/hop/render/river_renderer.dart';
import 'package:omaze/game/hop/render/rail_renderer.dart';

/// Dispatches row rendering to the appropriate terrain renderer.
class GroundRenderer {
  const GroundRenderer._();

  static void drawRow(Canvas canvas, HopRow row, HopRenderContext ctx) {
    final origin = ctx.tilePos(0, row.index.toDouble());
    final rect = Rect.fromLTWH(0, origin.dy - ctx.tile, ctx.size.width, ctx.tile + 1);
    // Skip drawing rows that sit fully above the horizon — sky owns that space.
    if (origin.dy < ctx.horizon - 4) return;
    switch (row.kind) {
      case RowKind.grass:
        _drawMeadow(canvas, row, rect, origin, ctx);
      case RowKind.road:
        _drawRoad(canvas, row, rect, origin, ctx);
      case RowKind.water:
        RiverRenderer.draw(canvas, row, rect, origin, ctx);
      case RowKind.rail:
        RailRenderer.draw(canvas, row, rect, origin, ctx);
    }
    _drawDistanceTint(canvas, rect, origin, ctx);
  }

  /// Light atmospheric perspective only on the farthest visible strip.
  static void _drawDistanceTint(Canvas canvas, Rect rect, Offset origin, HopRenderContext ctx) {
    final top = origin.dy - ctx.tile;
    final howFar = ((ctx.horizon + ctx.tile * 0.85 - top) / (ctx.tile * 0.85)).clamp(0.0, 1.0);
    if (howFar <= 0.15) return;
    final a = howFar * howFar * 0.22;
    canvas.drawRect(
      rect,
      Paint()..color = Color.fromRGBO(36, 24, 64, a),
    );
  }

  static void _drawMeadow(Canvas canvas, HopRow row, Rect rect, Offset origin, HopRenderContext ctx) {
    final even = row.index.isEven;
    final top = origin.dy - ctx.tile;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, origin.dy),
          even
              ? const [
                  Color(0xFF5CAD5A),
                  Color(0xFF3F8A42),
                  Color(0xFF2E6A34),
                  Color(0xFF245028),
                ]
              : const [
                  Color(0xFF4E9A4E),
                  Color(0xFF367838),
                  Color(0xFF285C2C),
                  Color(0xFF1E4422),
                ],
          const [0.0, 0.28, 0.68, 1.0],
        ),
    );

    // Warm sun-wash across the near half of the strip.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, origin.dy),
          const [Color(0x28F4E08A), Color(0x00000000), Color(0x22140C08)],
          const [0.0, 0.42, 1.0],
        ),
    );

    final seed = row.index * 47;
    for (var i = 0; i < 11; i++) {
      final x = ((seed + i * 73) % 97) / 97 * ctx.size.width;
      final y = origin.dy - ctx.tile * (0.18 + ((seed + i * 11) % 6) * 0.12);
      final wide = 36.0 + (i % 4) * 14;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: wide, height: 12 + (i % 3) * 5),
        Paint()..color = i.isEven ? const Color(0x2A1A4820) : const Color(0x2480C468),
      );
    }

    // Soft clover / moss specks.
    for (var i = 0; i < 16; i++) {
      final x = ((seed + i * 41) % 89) / 89 * ctx.size.width;
      final y = origin.dy - ctx.tile * (0.12 + ((seed + i * 17) % 8) * 0.09);
      canvas.drawCircle(
        Offset(x, y),
        1.6 + (i % 3) * 0.6,
        Paint()..color = i % 3 == 0 ? const Color(0x5568C070) : const Color(0x44305028),
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(0, origin.dy - 14, ctx.size.width, 14),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, origin.dy - 14),
          Offset(0, origin.dy),
          const [Color(0x00000000), Color(0x55321810)],
        ),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, top, ctx.size.width, 8),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, top + 8),
          const [Color(0x4468D070), Color(0x00000000)],
        ),
    );

    // Far, mid, then near grass so nearer blades sit in front.
    for (var depth = 0; depth < 4; depth++) {
      final scale = 0.55 + depth * 0.2;
      final rowY = 0.16 + depth * 0.2;
      final colorA = depth >= 3 ? const Color(0xCC14361A) : const Color(0xAA246830);
      final colorB = depth >= 3 ? const Color(0xBB286030) : const Color(0x9948A050);
      final colorC = depth <= 1 ? const Color(0x8868C05A) : const Color(0xAA3C9050);
      final cols = depth >= 2 ? 4 : 3;

      for (var i = -2; i < WorldGenerator.lanes + 2; i++) {
        final sway = ctx.wind(i.toDouble(), row.index.toDouble() + depth * 0.2, amp: 0.9 + depth * 0.18);
        final base = ctx.tilePos(i + 0.04, row.index + rowY);
        for (var k = 0; k < cols; k++) {
          final jitter = ((row.index * 13 + i * 7 + k * 3 + depth * 5) % 7) - 3.0;
          final tint = (i + k + depth).isEven
              ? colorA
              : ((i + k) % 3 == 0 ? colorC : colorB);
          _grassTuft(
            canvas,
            Offset(base.dx + 6 + k * (18.0 - depth) + jitter, base.dy),
            scale + ((i + k) % 3) * 0.08,
            k.isEven ? sway : -sway * 0.72,
            tint,
          );
        }
      }
    }

    for (final lane in row.flowers) {
      BloomRenderer.draw(canvas, lane, row.index, ctx);
    }
    for (final lane in row.shrooms) {
      ShroomRenderer.draw(canvas, lane, row.index, ctx);
    }
    for (final lane in row.crystals) {
      CrystalRenderer.draw(canvas, lane, row.index, ctx);
    }
    for (final lane in row.rocks) {
      RockRenderer.draw(canvas, lane, row.index, ctx);
    }
    for (final tree in row.trees) {
      TreeRenderer.draw(canvas, tree, row.index, ctx);
    }
    TreeRenderer.draw(canvas, -1, row.index, ctx);
    TreeRenderer.draw(canvas, WorldGenerator.lanes, row.index, ctx);
  }

  static void _grassTuft(Canvas canvas, Offset base, double scale, double sway, Color color) {
    final paint = Paint()..color = color;
    for (var i = -2; i <= 2; i++) {
      final lean = i * 3.4 * scale + sway;
      final h = (11 + (2 - i.abs()) * 3.2) * scale;
      final half = 1.15 * scale;
      final tip = Offset(base.dx + lean, base.dy - h);
      final path = Path()
        ..moveTo(base.dx - half, base.dy)
        ..quadraticBezierTo(
          base.dx + lean * 0.35,
          base.dy - h * 0.55,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          base.dx + lean * 0.35 + half * 0.4,
          base.dy - h * 0.5,
          base.dx + half,
          base.dy,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  static void _drawRoad(Canvas canvas, HopRow row, Rect rect, Offset origin, HopRenderContext ctx) {
    canvas.drawRect(rect, Paint()..color = const Color(0xFF2A2438));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, origin.dy - ctx.tile),
          Offset(0, origin.dy),
          const [Color(0x223C3458), Color(0x00000000), Color(0x33000000)],
          const [0.0, 0.5, 1.0],
        ),
    );
    final stone = Paint()..color = const Color(0x223C3650);
    for (var i = 0; i < 10; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 42.0 + 6, origin.dy - ctx.tile * 0.72, 28, 10),
          const Radius.circular(2),
        ),
        stone,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 42.0 + 18, origin.dy - ctx.tile * 0.38, 24, 9),
          const Radius.circular(2),
        ),
        stone,
      );
    }

    final above = ctx.rows[row.index + 1];
    final below = ctx.rows[row.index - 1];
    final curb = Paint()..color = const Color(0xFFC9A24A);
    if (above == null || above.kind != RowKind.road) {
      canvas.drawRect(Rect.fromLTWH(0, origin.dy - ctx.tile, ctx.size.width, 4), curb);
      _drawLanterns(canvas, origin.dy - ctx.tile + 8, ctx);
    }
    if (below == null || below.kind != RowKind.road) {
      canvas.drawRect(Rect.fromLTWH(0, origin.dy - 4, ctx.size.width, 4), curb);
    }

    final cobble = Paint()..color = const Color(0x18E8C36A);
    for (var i = 0; i < 14; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * 30.0 + 4 + (i.isEven ? 6 : 0),
            origin.dy - ctx.tile * 0.58,
            18,
            7,
          ),
          const Radius.circular(2),
        ),
        cobble,
      );
    }
    for (final car in row.movers) {
      VehicleRenderer.drawCarriage(canvas, row, car, ctx);
    }
  }

  static void _drawLanterns(Canvas canvas, double y, HopRenderContext ctx) {
    for (final x in [18.0, ctx.size.width - 18]) {
      canvas.drawRect(Rect.fromLTWH(x - 1.5, y - 16, 3, 16), Paint()..color = const Color(0xFF4A3A28));
      ctx.glow(canvas, Offset(x, y - 20), 12, const Color(0x55F4C542));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y - 20), width: 9, height: 10),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFF4C542),
      );
    }
  }
}
