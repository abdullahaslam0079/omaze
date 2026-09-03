import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:omaze/game/hop/domain/domain.dart';
import 'package:omaze/game/hop/render/render_context.dart';

/// Draws highly detailed, realistic fantasy vehicles on road rows.
class VehicleRenderer {
  const VehicleRenderer._();

  static void drawCarriage(Canvas canvas, HopRow row, Mover car, HopRenderContext ctx) {
    final baseP = ctx.tilePos(car.x, row.index + 0.18);
    final w = car.w * ctx.tile;
    final facing = row.dir > 0;

    // Multi-frequency suspension: chassis sway + axle bounce + road texture
    final chassisSway = math.sin(ctx.time * 14 + car.x * 3.1) * 0.08;
    final axleBounce = math.sin(ctx.time * 28 + car.x * 7.3) * 0.15 +
        math.sin(ctx.time * 42 + car.x * 11) * 0.07;
    final bounce = chassisSway + axleBounce;
    // Pitch from acceleration/braking feel
    final pitch = math.sin(ctx.time * 22 + car.x * 5.5) * 0.08 +
        math.sin(ctx.time * 9 + car.x * 2.0) * 0.04;
    // Slight lateral body roll
    final roll = math.sin(ctx.time * 11 + car.x * 4.2) * 0.06;
    final p = Offset(baseP.dx + roll, baseP.dy + bounce);

    if (car.truck) {
      _drawTruck(canvas, p, w, car, facing, ctx, pitch);
    } else {
      _drawCar(canvas, p, w, car, facing, ctx, pitch);
    }
  }

  // ══════════════════════════════════════════════
  //  SEDAN / HATCHBACK
  // ══════════════════════════════════════════════

  static void _drawCar(Canvas canvas, Offset p, double w, Mover car, bool facing, HopRenderContext ctx, double pitch) {
    final h = ctx.tile * 0.58;
    final darker = Color.lerp(car.color, const Color(0xFF0A0818), 0.40)!;
    final lighter = Color.lerp(car.color, const Color(0xFFFFFFFF), 0.18)!;
    final accent = Color.lerp(car.color, const Color(0xFFFFFFFF), 0.35)!;

    // ── Ground reflection streak (animated shimmer) ──
    final shimmer = (math.sin(ctx.time * 3.5 + car.x * 2) + 1) * 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(p.dx + 6, p.dy + 6, w - 12, 6),
        const Radius.circular(3),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(p.dx + 6, p.dy + 6),
          Offset(p.dx + 6, p.dy + 12),
          [car.color.withValues(alpha: 0.14 + shimmer * 0.08), const Color(0x00000000)],
        ),
    );

    // ── Ground shadow (dynamic spread based on bounce) ──
    final shadowSpread = 6 + (math.sin(ctx.time * 28 + car.x * 7.3).abs() * 2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(p.dx + w * 0.5, p.dy + 4), width: w + shadowSpread, height: 10),
      Paint()..color = const Color(0x55000000),
    );

    // ── Tire contact patches ──
    _tireContactShadow(canvas, Offset(p.dx + w * 0.18, p.dy + 1));
    _tireContactShadow(canvas, Offset(p.dx + w * 0.82, p.dy + 1));

    // ── Undercarriage with exhaust pipe ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(p.dx + 6, p.dy - 6, w - 12, 10), const Radius.circular(3)),
      Paint()..color = const Color(0xFF1A1410),
    );
    // Exhaust pipe detail
    final exhaustEnd = facing ? p.dx + 4 : p.dx + w - 4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(exhaustEnd - 3, p.dy - 2, 6, 3),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF3A3430),
    );
    canvas.drawCircle(
      Offset(exhaustEnd + (facing ? -2 : 2), p.dy - 0.5),
      1.2,
      Paint()..color = const Color(0xFF1A1410),
    );

    // ── Exhaust puff (subtle for sedan) ──
    final exhaustX = facing ? p.dx - 3 : p.dx + w + 3;
    final puff = (math.sin(ctx.time * 7 + car.x * 1.5) + 1) / 2;
    ctx.glow(canvas, Offset(exhaustX, p.dy), 3 + puff * 2, Color.fromRGBO(180, 180, 190, 0.06 + puff * 0.04));

    // ── Main body (lower half) ──
    final bodyRect = Rect.fromLTWH(p.dx, p.dy - h * 0.52, w, h * 0.52);
    final bodyRR = RRect.fromRectAndRadius(bodyRect, const Radius.circular(10));
    canvas.drawRRect(bodyRR, Paint()..color = car.color);
    // Metallic gradient sheen
    canvas.drawRRect(
      bodyRR,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(p.dx, bodyRect.top),
          Offset(p.dx, bodyRect.bottom),
          [lighter.withValues(alpha: 0.35), car.color, darker.withValues(alpha: 0.5)],
          const [0.0, 0.45, 1.0],
        ),
    );
    // Moving environment reflection on body (animated horizontal sweep)
    final reflSweep = (ctx.time * 0.8 + car.x * 0.3) % 1.0;
    final reflX = p.dx + w * reflSweep;
    canvas.drawRect(
      Rect.fromLTWH(reflX - 3, bodyRect.top + 2, 6, bodyRect.height - 4),
      Paint()
        ..color = const Color(0x0DFFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── Fender arches over wheels ──
    _drawFenderArch(canvas, Offset(p.dx + w * 0.18, p.dy - 2), 10, darker);
    _drawFenderArch(canvas, Offset(p.dx + w * 0.82, p.dy - 2), 10, darker);

    // ── Side trim line (chrome strip) ──
    canvas.drawLine(
      Offset(p.dx + 6, p.dy - h * 0.22),
      Offset(p.dx + w - 6, p.dy - h * 0.22),
      Paint()
        ..color = lighter.withValues(alpha: 0.25)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );
    // Secondary lower accent line
    canvas.drawLine(
      Offset(p.dx + 8, p.dy - h * 0.08),
      Offset(p.dx + w - 8, p.dy - h * 0.08),
      Paint()
        ..color = darker.withValues(alpha: 0.15)
        ..strokeWidth = 0.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Door panels ──
    final doorY1 = p.dy - h * 0.48;
    final doorY2 = p.dy - 4;
    final doorMid = p.dx + w * 0.5;
    final doorPaint = Paint()
      ..color = darker.withValues(alpha: 0.18)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(doorMid - 1, doorY1 + 2), Offset(doorMid - 1, doorY2), doorPaint);
    canvas.drawLine(Offset(doorMid + w * 0.14, doorY1 + 2), Offset(doorMid + w * 0.14, doorY2), doorPaint);
    _drawDoorHandle(canvas, Offset(doorMid + 4, p.dy - h * 0.30), lighter);
    _drawDoorHandle(canvas, Offset(doorMid + w * 0.14 + 4, p.dy - h * 0.30), lighter);

    // ── Hood + trunk (shaped top profile) ──
    final cabinL = p.dx + w * 0.22;
    final cabinR = p.dx + w * 0.78;
    final cabTop = p.dy - h + pitch;
    final beltLine = p.dy - h * 0.52;

    final hoodEdge = facing ? p.dx + w - 4 : p.dx + 4;
    final hoodPillar = facing ? cabinR : cabinL;
    final hoodCpX = facing ? p.dx + w * 0.86 : p.dx + w * 0.14;
    final trunkEdge = facing ? p.dx + 4 : p.dx + w - 4;
    final trunkPillar = facing ? cabinL : cabinR;
    final trunkCpX = facing ? p.dx + w * 0.14 : p.dx + w * 0.86;

    // Hood slope (front)
    final hood = Path()
      ..moveTo(hoodEdge, beltLine)
      ..lineTo(hoodPillar, beltLine)
      ..lineTo(hoodPillar, cabTop + 4)
      ..quadraticBezierTo(hoodCpX, cabTop + 6, hoodEdge, beltLine);
    canvas.drawPath(hood, Paint()..color = car.color);
    canvas.drawPath(
      hood,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, cabTop),
          Offset(0, beltLine),
          [lighter.withValues(alpha: 0.30), car.color],
        ),
    );
    // Hood seam line
    canvas.drawLine(
      Offset(hoodEdge + (facing ? -4 : 4), beltLine - 2),
      Offset(hoodPillar + (facing ? 2 : -2), cabTop + 7),
      Paint()
        ..color = darker.withValues(alpha: 0.15)
        ..strokeWidth = 0.6,
    );
    // Hood vent slits
    final ventX = (hoodEdge + hoodPillar) * 0.5;
    final ventPaint = Paint()
      ..color = darker.withValues(alpha: 0.12)
      ..strokeWidth = 0.4;
    canvas.drawLine(Offset(ventX - 3, beltLine - 4), Offset(ventX + 3, beltLine - 4), ventPaint);
    canvas.drawLine(Offset(ventX - 2, beltLine - 6), Offset(ventX + 2, beltLine - 6), ventPaint);

    // Trunk slope (rear)
    final trunk = Path()
      ..moveTo(trunkPillar, beltLine)
      ..lineTo(trunkEdge, beltLine)
      ..quadraticBezierTo(trunkCpX, cabTop + 6, trunkPillar, cabTop + 4)
      ..lineTo(trunkPillar, beltLine);
    canvas.drawPath(trunk, Paint()..color = car.color);
    canvas.drawPath(
      trunk,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, cabTop),
          Offset(0, beltLine),
          [lighter.withValues(alpha: 0.25), car.color],
        ),
    );
    // Trunk badge (small circle)
    final badgeX = (trunkEdge + trunkPillar) * 0.5;
    canvas.drawCircle(
      Offset(badgeX, beltLine - 4),
      1.8,
      Paint()..color = accent.withValues(alpha: 0.30),
    );

    // ── Cabin (windshield pillars) ──
    final cabin = Path()
      ..moveTo(cabinL, beltLine)
      ..lineTo(cabinL + 3, cabTop + 2)
      ..quadraticBezierTo(p.dx + w * 0.5, cabTop - 4, cabinR - 3, cabTop + 2)
      ..lineTo(cabinR, beltLine)
      ..close();
    canvas.drawPath(cabin, Paint()..color = darker);
    canvas.drawPath(
      cabin,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, cabTop - 4),
          Offset(0, beltLine),
          [const Color(0x33FFFFFF), const Color(0x00000000)],
        ),
    );

    // ── Windows with interior silhouettes ──
    final winTop = cabTop + 5;
    final winBot = beltLine - 2;
    final winMid = p.dx + w * 0.5;
    _drawWindowWithInterior(canvas, Offset(cabinL + 4, winTop), Offset(winMid - 2, winTop), Offset(winMid - 2, winBot), Offset(cabinL + 3, winBot), ctx, true);
    _drawWindowWithInterior(canvas, Offset(winMid + 2, winTop), Offset(cabinR - 4, winTop), Offset(cabinR - 3, winBot), Offset(winMid + 2, winBot), ctx, false);

    // ── Windshield wiper (animated sweep) ──
    final wiperAngle = math.sin(ctx.time * 3.0) * 0.4;
    final wiperBase = Offset(facing ? cabinR - 6 : cabinL + 6, beltLine - 1);
    final wiperLen = (winBot - winTop) * 0.6;
    final wiperDir = facing ? -1.0 : 1.0;
    canvas.drawLine(
      wiperBase,
      wiperBase + Offset(wiperDir * 8 + wiperAngle * 4, -wiperLen),
      Paint()
        ..color = const Color(0x66202020)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );

    // ── Bumpers with reflectors ──
    final bumperPaint = Paint()..color = const Color(0xFF3A3440);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(p.dx - 2, p.dy - h * 0.38, 5, h * 0.20), const Radius.circular(2)),
      bumperPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(p.dx + w - 3, p.dy - h * 0.38, 5, h * 0.20), const Radius.circular(2)),
      bumperPaint,
    );
    // Rear reflectors (amber dots on bumper)
    final rearBumperX = facing ? p.dx : p.dx + w - 2;
    canvas.drawCircle(Offset(rearBumperX, p.dy - h * 0.30), 1.2, Paint()..color = const Color(0xCCFF8800));

    // ── Front grille (enhanced with chrome surround) ──
    final grilleX = facing ? p.dx + w - 3 : p.dx - 1;
    _drawGrille(canvas, Offset(grilleX, p.dy - h * 0.44), h * 0.16, facing);

    // ── Headlights / Taillights ──
    final frontX = facing ? p.dx + w - 2 : p.dx + 2;
    final rearX = facing ? p.dx + 2 : p.dx + w - 2;
    _drawHeadlight(canvas, Offset(frontX, p.dy - h * 0.34), facing, ctx);
    _drawTaillight(canvas, Offset(rearX, p.dy - h * 0.34), ctx);

    // ── Fog lights (small, low on bumper) ──
    _drawFogLight(canvas, Offset(frontX, p.dy - h * 0.18), facing, ctx);

    // ── Turn signals (amber, blinking with smooth fade) ──
    final blinkPhase = (math.sin(ctx.time * 5.0) + 1) * 0.5;
    if (blinkPhase > 0.3) {
      _drawTurnSignal(canvas, Offset(frontX, p.dy - h * 0.46), facing, blinkPhase);
    }

    // ── Side mirror ──
    final mirrorX = facing ? p.dx + w * 0.76 : p.dx + w * 0.24;
    _drawSideMirror(canvas, Offset(mirrorX, p.dy - h * 0.50), darker, lighter);

    // ── License plate (rear) with light ──
    _drawLicensePlate(canvas, Offset(rearX + (facing ? -1 : -3), p.dy - h * 0.18));
    // Plate illumination
    canvas.drawCircle(
      Offset(rearX + (facing ? 3 : 1), p.dy - h * 0.24),
      1.5,
      Paint()..color = const Color(0x33FFFFEE),
    );

    // ── Wheels with brake disc glow ──
    final spin = facing ? 1 : -1;
    _drawWheel(canvas, Offset(p.dx + w * 0.18, p.dy + 1), 7.5, ctx, spin);
    _drawWheel(canvas, Offset(p.dx + w * 0.82, p.dy + 1), 7.5, ctx, spin);
    // Brake disc heat glow (subtle warm shimmer behind wheels)
    _drawBrakeGlow(canvas, Offset(p.dx + w * 0.18, p.dy + 1), 7.5, ctx);
    _drawBrakeGlow(canvas, Offset(p.dx + w * 0.82, p.dy + 1), 7.5, ctx);

    // ── Mud flaps ──
    final flapOff = facing ? -8.0 : 8.0;
    _drawMudFlap(canvas, Offset(p.dx + w * 0.18 + flapOff, p.dy + 2), darker);
    _drawMudFlap(canvas, Offset(p.dx + w * 0.82 + flapOff, p.dy + 2), darker);

    // ── Roof edge highlight ──
    canvas.drawLine(
      Offset(cabinL + 6, cabTop + 1),
      Offset(cabinR - 6, cabTop + 1),
      Paint()
        ..color = const Color(0x44FFFFFF)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );

    // ── Antenna (small, with subtle sway) ──
    final antennaSway = math.sin(ctx.time * 6 + car.x * 2) * 1.5;
    canvas.drawLine(
      Offset(cabinR - 4, cabTop + 1),
      Offset(cabinR - 2 + antennaSway, cabTop - 8),
      Paint()
        ..color = const Color(0xFF2A2430)
        ..strokeWidth = 0.7
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cabinR - 2 + antennaSway, cabTop - 8), 1.0, Paint()..color = const Color(0xFFFF4444));

    // ── Roof sunroof glass panel ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cabinL + 10, cabTop + 3, cabinR - cabinL - 20, 4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0x220E1420),
    );
  }

  // ══════════════════════════════════════════════
  //  TRUCK / VAN
  // ══════════════════════════════════════════════

  static void _drawTruck(Canvas canvas, Offset p, double w, Mover car, bool facing, HopRenderContext ctx, double pitch) {
    final h = ctx.tile * 0.68;
    final darker = Color.lerp(car.color, const Color(0xFF0A0818), 0.45)!;
    final lighter = Color.lerp(car.color, const Color(0xFFFFFFFF), 0.15)!;

    // ── Ground reflection streak ──
    final shimmer = (math.sin(ctx.time * 3.5 + car.x * 2) + 1) * 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(p.dx + 10, p.dy + 7, w - 20, 6),
        const Radius.circular(2),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(p.dx + 10, p.dy + 7),
          Offset(p.dx + 10, p.dy + 13),
          [car.color.withValues(alpha: 0.12 + shimmer * 0.06), const Color(0x00000000)],
        ),
    );

    // ── Ground shadow (dynamic) ──
    final shadowSpread = 10 + (math.sin(ctx.time * 28 + car.x * 7.3).abs() * 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(p.dx + w * 0.5, p.dy + 5), width: w + shadowSpread, height: 12),
      Paint()..color = const Color(0x55000000),
    );

    // ── Tire contact patches ──
    _tireContactShadow(canvas, Offset(p.dx + w * 0.16, p.dy + 1));
    _tireContactShadow(canvas, Offset(p.dx + w * 0.55, p.dy + 1));
    _tireContactShadow(canvas, Offset(p.dx + w * 0.82, p.dy + 1));

    // ── Undercarriage with details ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(p.dx + 8, p.dy - 6, w - 16, 10), const Radius.circular(3)),
      Paint()..color = const Color(0xFF1A1410),
    );
    // Drive shaft
    canvas.drawLine(
      Offset(p.dx + w * 0.25, p.dy - 1),
      Offset(p.dx + w * 0.75, p.dy - 1),
      Paint()
        ..color = const Color(0xFF2A2420)
        ..strokeWidth = 1.5,
    );
    // Fuel tank (mid-undercarriage rectangle)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(p.dx + w * 0.35, p.dy - 4, w * 0.18, 5),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF282018),
    );

    // ── Cab section ──
    final cabW = w * 0.32;
    final cabX = facing ? p.dx + w - cabW : p.dx;
    final cabTop = p.dy - h + pitch;
    final cabRect = Rect.fromLTWH(cabX, cabTop, cabW, h + pitch.abs());
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabRect, const Radius.circular(8)),
      Paint()..color = car.color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabRect, const Radius.circular(8)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cabX, cabRect.top),
          Offset(cabX, cabRect.bottom),
          [lighter.withValues(alpha: 0.30), car.color, darker.withValues(alpha: 0.4)],
          const [0.0, 0.4, 1.0],
        ),
    );

    // Cab door panel
    final cabDoorX = cabX + cabW * 0.5;
    canvas.drawLine(
      Offset(cabDoorX, cabTop + cabW * 0.45),
      Offset(cabDoorX, p.dy - 4),
      Paint()
        ..color = darker.withValues(alpha: 0.18)
        ..strokeWidth = 0.7,
    );
    _drawDoorHandle(canvas, Offset(cabDoorX + 4, p.dy - h * 0.38), lighter);

    // Cab step bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cabX + 2, p.dy - 2, cabW - 4, 2.5),
        const Radius.circular(1),
      ),
      Paint()..color = const Color(0xFF4A4440),
    );

    // Cab windshield
    final winX = cabX + (facing ? cabW * 0.15 : cabW * 0.12);
    final winW = cabW * 0.70;
    _drawWindowWithInterior(
      canvas,
      Offset(winX, cabTop + 5),
      Offset(winX + winW, cabTop + 5),
      Offset(winX + winW, cabTop + h * 0.42),
      Offset(winX, cabTop + h * 0.42),
      ctx,
      true,
    );

    // Cab windshield wiper (animated)
    final wiperAngle = math.sin(ctx.time * 2.5) * 0.3;
    final wiperBase = Offset(winX + winW * 0.5, cabTop + h * 0.40);
    canvas.drawLine(
      wiperBase,
      wiperBase + Offset(wiperAngle * 5, -12),
      Paint()
        ..color = const Color(0x55202020)
        ..strokeWidth = 0.7
        ..strokeCap = StrokeCap.round,
    );

    // ── Roof-mounted running lights (3 amber dots on cab top) ──
    final cabMidX = cabX + cabW * 0.5;
    for (var i = -1; i <= 1; i++) {
      final lx = cabMidX + i * 5.0;
      final glow = (math.sin(ctx.time * 4 + i * 1.2) + 1) * 0.5;
      canvas.drawCircle(
        Offset(lx, cabTop - 1),
        1.5,
        Paint()..color = Color.fromRGBO(255, 180, 30, 0.50 + glow * 0.30),
      );
    }

    // ── Cargo bed ──
    final cargoX = facing ? p.dx : p.dx + cabW - 4;
    final cargoW = w - cabW + 4;
    final cargoH = h * 0.72;
    final cargoTop = p.dy - cargoH;
    final cargoColor = Color.lerp(car.color, const Color(0xFF2A1A10), 0.40)!;
    final cargoRect = Rect.fromLTWH(cargoX, cargoTop, cargoW, cargoH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cargoRect, const Radius.circular(6)),
      Paint()..color = cargoColor,
    );
    // Cargo gradient for depth
    canvas.drawRRect(
      RRect.fromRectAndRadius(cargoRect, const Radius.circular(6)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cargoX, cargoTop),
          Offset(cargoX, p.dy),
          [lighter.withValues(alpha: 0.12), cargoColor, darker.withValues(alpha: 0.3)],
          const [0.0, 0.4, 1.0],
        ),
    );
    // Canvas cover ridges
    final ridgePaint = Paint()
      ..color = Color.lerp(car.color, const Color(0xFF1A1210), 0.55)!.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 5; i++) {
      final rx = cargoX + cargoW * (i / 5);
      canvas.drawLine(Offset(rx, cargoTop + 4), Offset(rx, p.dy - 2), ridgePaint);
    }
    // Cargo top highlight
    canvas.drawLine(
      Offset(cargoX + 4, cargoTop + 2),
      Offset(cargoX + cargoW - 4, cargoTop + 2),
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );
    // Cargo latch (rear)
    final latchX = facing ? cargoX : cargoX + cargoW - 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(latchX, cargoTop + cargoH * 0.3, 3, cargoH * 0.12),
        const Radius.circular(1),
      ),
      Paint()..color = const Color(0xFFA08860),
    );
    // Hinge details on cargo door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(latchX, cargoTop + cargoH * 0.55, 2.5, cargoH * 0.08),
        const Radius.circular(0.5),
      ),
      Paint()..color = const Color(0xFF8A7850),
    );

    // ── Roof rack (two rails + crossbars) ──
    final rackY = cargoTop - 3;
    final rackPaint = Paint()
      ..color = const Color(0xFF4A4040)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cargoX + 6, rackY), Offset(cargoX + cargoW - 6, rackY), rackPaint);
    canvas.drawLine(Offset(cargoX + 6, rackY + 3), Offset(cargoX + cargoW - 6, rackY + 3), rackPaint);
    for (var i = 0; i < 3; i++) {
      final cx = cargoX + 8 + (cargoW - 16) * (i / 2);
      canvas.drawLine(Offset(cx, rackY), Offset(cx, rackY + 3), rackPaint);
    }

    // ── Fender arches ──
    final cabWheelX = cabX + cabW * 0.45;
    _drawFenderArch(canvas, Offset(cabWheelX, p.dy - 2), 11, darker);
    _drawFenderArch(canvas, Offset(cargoX + cargoW * 0.35, p.dy - 2), 11, darker);
    _drawFenderArch(canvas, Offset(cargoX + cargoW * 0.75, p.dy - 2), 11, darker);

    // ── Bumpers with tow hook ──
    final frontEnd = facing ? p.dx + w : p.dx;
    final rearEnd = facing ? p.dx : p.dx + w;
    final bumperPaint = Paint()..color = const Color(0xFF3A3440);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(frontEnd - (facing ? 4 : -1), p.dy - h * 0.32, 5, h * 0.18),
        const Radius.circular(2),
      ),
      bumperPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rearEnd - (facing ? -1 : 4), p.dy - cargoH * 0.42, 5, cargoH * 0.20),
        const Radius.circular(2),
      ),
      bumperPaint,
    );
    // Tow hook on rear bumper
    canvas.drawCircle(
      Offset(rearEnd + (facing ? 1 : -1), p.dy - cargoH * 0.25),
      2.0,
      Paint()
        ..color = const Color(0xFF5A5450)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── Front grille (larger for truck) ──
    final grilleX = facing ? p.dx + w - 3 : p.dx - 1;
    _drawGrille(canvas, Offset(grilleX, p.dy - h * 0.46), h * 0.18, facing);

    // ── Lights ──
    _drawHeadlight(canvas, Offset(facing ? p.dx + w - 1 : p.dx + 1, p.dy - h * 0.32), facing, ctx);
    _drawTaillight(canvas, Offset(facing ? p.dx + 1 : p.dx + w - 1, p.dy - cargoH * 0.38), ctx);

    // ── Fog lights ──
    _drawFogLight(canvas, Offset(facing ? p.dx + w - 1 : p.dx + 1, p.dy - h * 0.18), facing, ctx);

    // ── Turn signals (smooth fade) ──
    final blinkPhase = (math.sin(ctx.time * 5.0) + 1) * 0.5;
    if (blinkPhase > 0.3) {
      _drawTurnSignal(canvas, Offset(facing ? p.dx + w - 1 : p.dx + 1, p.dy - h * 0.46), facing, blinkPhase);
    }

    // ── Side marker lights (amber, on cargo bed sides) ──
    final markerBlink = (math.sin(ctx.time * 3.0 + 0.8) + 1) * 0.5;
    final markerY = cargoTop + cargoH * 0.5;
    for (var i = 0; i < 2; i++) {
      final mx = cargoX + cargoW * (0.25 + i * 0.5);
      canvas.drawCircle(
        Offset(mx, markerY),
        1.2,
        Paint()..color = Color.fromRGBO(255, 160, 0, 0.35 + markerBlink * 0.25),
      );
    }

    // ── License plate (rear) ──
    _drawLicensePlate(canvas, Offset(
      facing ? p.dx + 3 : p.dx + w - 7,
      p.dy - cargoH * 0.20,
    ));

    // ── Exhaust puff (heavier for truck) ──
    final exhaustX = facing ? p.dx - 4 : p.dx + w + 4;
    final puff = (math.sin(ctx.time * 6 + car.x) + 1) / 2;
    ctx.glow(canvas, Offset(exhaustX, p.dy - 2), 5 + puff * 4, Color.fromRGBO(160, 160, 170, 0.14 + puff * 0.10));
    final puff2 = (math.sin(ctx.time * 5.2 + car.x + 1.5) + 1) / 2;
    final trail = facing ? -1.0 : 1.0;
    ctx.glow(canvas, Offset(exhaustX + trail * 8, p.dy - 4), 3.5 + puff2 * 3, Color.fromRGBO(150, 150, 160, 0.08 + puff2 * 0.06));
    // Third trailing puff (diesely)
    final puff3 = (math.sin(ctx.time * 4.3 + car.x + 3.0) + 1) / 2;
    ctx.glow(canvas, Offset(exhaustX + trail * 16, p.dy - 6), 3 + puff3 * 2, Color.fromRGBO(140, 140, 150, 0.04 + puff3 * 0.03));

    // ── Wheels (3 axles) with brake glow ──
    final spin = facing ? 1 : -1;
    _drawWheel(canvas, Offset(cabWheelX, p.dy + 1), 8.0, ctx, spin);
    _drawWheel(canvas, Offset(cargoX + cargoW * 0.35, p.dy + 1), 8.0, ctx, spin);
    _drawWheel(canvas, Offset(cargoX + cargoW * 0.75, p.dy + 1), 8.0, ctx, spin);
    _drawBrakeGlow(canvas, Offset(cabWheelX, p.dy + 1), 8.0, ctx);
    _drawBrakeGlow(canvas, Offset(cargoX + cargoW * 0.35, p.dy + 1), 8.0, ctx);
    _drawBrakeGlow(canvas, Offset(cargoX + cargoW * 0.75, p.dy + 1), 8.0, ctx);

    // ── Mud flaps (with spray particles) ──
    final flapOff = facing ? -9.0 : 9.0;
    _drawMudFlap(canvas, Offset(cabWheelX + flapOff, p.dy + 2), darker);
    _drawMudFlap(canvas, Offset(cargoX + cargoW * 0.35 + flapOff, p.dy + 2), darker);
    _drawMudFlap(canvas, Offset(cargoX + cargoW * 0.75 + flapOff, p.dy + 2), darker);

    // Wheel spray (tiny particles behind rear wheels)
    _drawWheelSpray(canvas, Offset(cargoX + cargoW * 0.75 + flapOff, p.dy + 1), facing, ctx);

    // ── Side mirror ──
    final mirY = cabTop + 14;
    final mirX = facing ? cabX + cabW - 2 : cabX + 2;
    _drawSideMirror(canvas, Offset(mirX, mirY), darker, lighter);
  }

  // ══════════════════════════════════════════════
  //  SHARED DRAWING HELPERS
  // ══════════════════════════════════════════════

  static void _drawWindowWithInterior(Canvas canvas, Offset tl, Offset tr, Offset br, Offset bl, HopRenderContext ctx, bool showDriver) {
    final path = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();
    // Dark glass base
    canvas.drawPath(path, Paint()..color = const Color(0xDD0E1420));

    // Interior silhouette (driver headrest / passenger shadow)
    if (showDriver) {
      final cx = (tl.dx + tr.dx) * 0.5;
      final cy = (tl.dy + bl.dy) * 0.5;
      // Headrest shape
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - 1), width: 4, height: 5),
        Paint()..color = const Color(0x220A0A0A),
      );
      // Shoulder silhouette
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 3), width: 7, height: 3),
        Paint()..color = const Color(0x180A0A0A),
      );
    }

    // Sky reflection gradient (animated sweep)
    final reflPhase = (ctx.time * 0.6) % 1.0;
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          tl,
          br,
          [
            Color.fromRGBO(96, 120, 152, 0.20 + reflPhase * 0.08),
            const Color(0x1120304A),
            Color.fromRGBO(80, 104, 120, 0.10 + (1 - reflPhase) * 0.06),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );
    // Top edge glint
    canvas.drawLine(
      Offset(tl.dx + 1, tl.dy + 1),
      Offset(tr.dx - 1, tr.dy + 1),
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 0.6,
    );
    // Bottom edge subtle glint
    canvas.drawLine(
      Offset(bl.dx + 1, bl.dy - 1),
      Offset(br.dx - 1, br.dy - 1),
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..strokeWidth = 0.4,
    );
  }

  static void _drawHeadlight(Canvas canvas, Offset c, bool facing, HopRenderContext ctx) {
    // Dynamic warm glow (pulsing intensity)
    final glowPulse = 0.9 + math.sin(ctx.time * 2.0) * 0.1;
    ctx.glow(canvas, c, 14 * glowPulse, Color.fromRGBO(255, 248, 224, 0.22 * glowPulse));
    // Housing
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 8, height: 6),
      Paint()..color = const Color(0xFF2A2830),
    );
    // Lens
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 7, height: 5.5),
      Paint()..color = const Color(0xFFFFF6D8),
    );
    // Bright center
    canvas.drawCircle(c, 2.0, Paint()..color = const Color(0xFFFFFFF0));
    // Lens highlight
    canvas.drawCircle(c + const Offset(-1, -1), 1.0, Paint()..color = const Color(0x55FFFFFF));
    // DRL ring (daytime running light outline)
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 7.5, height: 6),
      Paint()
        ..color = Color.fromRGBO(255, 255, 240, 0.20 * glowPulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
    // Beam projection (wider, more realistic cone with falloff)
    final beamDir = facing ? 1.0 : -1.0;
    final beam = Path()
      ..moveTo(c.dx + beamDir * 4, c.dy - 2.5)
      ..lineTo(c.dx + beamDir * 28, c.dy - 8)
      ..lineTo(c.dx + beamDir * 28, c.dy + 8)
      ..lineTo(c.dx + beamDir * 4, c.dy + 2.5)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(c.dx + beamDir * 4, c.dy),
          Offset(c.dx + beamDir * 28, c.dy),
          [Color.fromRGBO(255, 248, 208, 0.06 * glowPulse), const Color(0x00FFF8D0)],
        ),
    );
  }

  static void _drawTaillight(Canvas canvas, Offset c, HopRenderContext ctx) {
    // Pulsing brake glow
    final brakePulse = 0.85 + math.sin(ctx.time * 1.5 + 0.5) * 0.15;
    canvas.drawCircle(
      c, 6 * brakePulse,
      Paint()
        ..color = Color.fromRGBO(255, 34, 0, 0.18 * brakePulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Housing
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 6, height: 5),
      Paint()..color = const Color(0xFFCC2222),
    );
    // Bright center
    canvas.drawCircle(c, 1.6, Paint()..color = const Color(0xFFFF5544));
    // Lens highlight
    canvas.drawCircle(c + const Offset(-0.5, -0.8), 0.8, Paint()..color = const Color(0x44FFFFFF));
    // Reflector strip below
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c + const Offset(0, 4), width: 5, height: 1.5),
        const Radius.circular(0.5),
      ),
      Paint()..color = const Color(0x66CC2222),
    );
  }

  static void _drawFogLight(Canvas canvas, Offset c, bool facing, HopRenderContext ctx) {
    final glowPulse = 0.8 + math.sin(ctx.time * 1.8 + 1.0) * 0.2;
    ctx.glow(canvas, c, 6 * glowPulse, Color.fromRGBO(255, 240, 180, 0.10 * glowPulse));
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 4, height: 3),
      Paint()..color = const Color(0xFF2A2830),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 3, height: 2.2),
      Paint()..color = Color.fromRGBO(255, 246, 216, 0.7 * glowPulse),
    );
  }

  static void _drawTurnSignal(Canvas canvas, Offset c, bool facing, double intensity) {
    canvas.drawCircle(
      c, 4,
      Paint()
        ..color = Color.fromRGBO(255, 170, 0, 0.25 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 4, height: 3),
      Paint()..color = Color.fromRGBO(255, 187, 34, 0.5 + intensity * 0.5),
    );
  }

  static void _drawWheel(Canvas canvas, Offset c, double r, HopRenderContext ctx, [int spinDir = 1]) {
    // Tire
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF1A1410));
    // Tire sidewall ring
    canvas.drawCircle(
      c, r - 0.8,
      Paint()
        ..color = const Color(0xFF2E2820)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    // Tire tread texture (more detailed)
    final treadPaint = Paint()
      ..color = const Color(0xFF302A22)
      ..strokeWidth = 0.5;
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 + ctx.time * 6 * spinDir;
      final inner = c + Offset(math.cos(a) * (r - 2), math.sin(a) * (r - 2));
      final outer = c + Offset(math.cos(a) * r, math.sin(a) * r);
      canvas.drawLine(inner, outer, treadPaint);
    }
    // Rim
    canvas.drawCircle(c, r * 0.60, Paint()..color = const Color(0xFFB8A070));
    // Rim edge ring
    canvas.drawCircle(
      c, r * 0.60,
      Paint()
        ..color = const Color(0xFF9A8458)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    // Hubcap shine (animated rotation highlight)
    final shineAngle = ctx.time * 3 * spinDir;
    canvas.drawCircle(
      c, r * 0.58,
      Paint()
        ..shader = ui.Gradient.radial(
          c + Offset(math.cos(shineAngle) * r * 0.15, math.sin(shineAngle) * r * 0.15 - r * 0.1),
          r * 0.6,
          const [Color(0x66FFFFFF), Color(0x00FFFFFF)],
        ),
    );
    // Center lug nut
    canvas.drawCircle(c, r * 0.20, Paint()..color = const Color(0xFFD8C088));
    canvas.drawCircle(
      c, r * 0.20,
      Paint()
        ..color = const Color(0xFFAA9060)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
    // Spoke lines (5 spokes, slightly thicker)
    final spokePaint = Paint()
      ..color = const Color(0x66A08850)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5 + ctx.time * 6 * spinDir;
      canvas.drawLine(
        c + Offset(math.cos(a) * r * 0.22, math.sin(a) * r * 0.22),
        c + Offset(math.cos(a) * r * 0.56, math.sin(a) * r * 0.56),
        spokePaint,
      );
    }
    // Lug bolt details (5 small dots)
    final lugPaint = Paint()..color = const Color(0xFF9A8860);
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5 + ctx.time * 6 * spinDir + 0.3;
      canvas.drawCircle(
        c + Offset(math.cos(a) * r * 0.38, math.sin(a) * r * 0.38),
        0.6,
        lugPaint,
      );
    }
  }

  static void _drawBrakeGlow(Canvas canvas, Offset c, double r, HopRenderContext ctx) {
    final heat = (math.sin(ctx.time * 1.2 + c.dx * 0.1) + 1) * 0.5;
    if (heat > 0.3) {
      canvas.drawCircle(
        c, r * 0.55,
        Paint()
          ..color = Color.fromRGBO(255, 100, 30, 0.04 * heat)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  static void _drawWheelSpray(Canvas canvas, Offset pos, bool facing, HopRenderContext ctx) {
    final dir = facing ? -1.0 : 1.0;
    for (var i = 0; i < 4; i++) {
      final phase = (ctx.time * 8 + i * 1.7) % 3.0;
      if (phase > 2.0) continue;
      final t = phase / 2.0;
      final px = pos.dx + dir * (4 + t * 12);
      final py = pos.dy - t * 6 + math.sin(phase * 5 + i) * 2;
      final alpha = (1.0 - t) * 0.15;
      canvas.drawCircle(
        Offset(px, py),
        0.8 + t * 1.2,
        Paint()..color = Color.fromRGBO(180, 175, 165, alpha),
      );
    }
  }

  static void _drawFenderArch(Canvas canvas, Offset center, double r, Color color) {
    final arch = Path()
      ..moveTo(center.dx - r, center.dy)
      ..arcTo(
        Rect.fromCenter(center: center, width: r * 2, height: r * 1.6),
        math.pi, -math.pi, false,
      );
    canvas.drawPath(
      arch,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    // Inner lip highlight
    final innerArch = Path()
      ..moveTo(center.dx - r + 1, center.dy)
      ..arcTo(
        Rect.fromCenter(center: center, width: (r - 1) * 2, height: (r - 1) * 1.6),
        math.pi, -math.pi, false,
      );
    canvas.drawPath(
      innerArch,
      Paint()
        ..color = const Color(0x11FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  static void _drawDoorHandle(Canvas canvas, Offset pos, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx, pos.dy, 6, 2.2),
        const Radius.circular(1),
      ),
      Paint()..color = color.withValues(alpha: 0.45),
    );
    // Chrome highlight on top edge
    canvas.drawLine(
      Offset(pos.dx + 0.5, pos.dy),
      Offset(pos.dx + 5.5, pos.dy),
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..strokeWidth = 0.4,
    );
    // Keyhole dot
    canvas.drawCircle(Offset(pos.dx + 1.5, pos.dy + 1.1), 0.6, Paint()..color = const Color(0xFF1A1420));
  }

  static void _drawSideMirror(Canvas canvas, Offset pos, Color darker, Color lighter) {
    // Mirror arm
    canvas.drawLine(
      pos,
      pos + const Offset(0, 4),
      Paint()
        ..color = darker
        ..strokeWidth = 1.2,
    );
    // Mirror housing
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 5.5, height: 3.8),
      Paint()..color = darker,
    );
    // Mirror glass
    canvas.drawOval(
      Rect.fromCenter(center: pos + const Offset(0.3, 0), width: 4, height: 2.6),
      Paint()..color = const Color(0xCC607888),
    );
    // Glass highlight
    canvas.drawCircle(pos + const Offset(-0.5, -0.4), 0.7, Paint()..color = const Color(0x44FFFFFF));
    // Turn indicator on mirror housing
    canvas.drawCircle(
      pos + const Offset(0, 1.5),
      0.5,
      Paint()..color = const Color(0x55FFAA00),
    );
  }

  static void _drawGrille(Canvas canvas, Offset pos, double height, bool facing) {
    final gw = 4.0;
    final slats = 4;
    final slatH = height / (slats * 2 + 1);
    // Chrome surround
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx - (facing ? 0 : gw), pos.dy - 1, gw + 1, height + 2),
        const Radius.circular(1),
      ),
      Paint()
        ..color = const Color(0xFF5A5450)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    final paint = Paint()
      ..color = const Color(0xFF2A2830)
      ..strokeWidth = 0.8;
    for (var i = 0; i < slats; i++) {
      final y = pos.dy + slatH * (i * 2 + 1);
      canvas.drawLine(
        Offset(pos.dx, y),
        Offset(pos.dx + (facing ? gw : -gw), y),
        paint,
      );
    }
    // Brand badge (tiny circle in center)
    canvas.drawCircle(
      Offset(pos.dx + (facing ? gw * 0.5 : -gw * 0.5), pos.dy + height * 0.5),
      1.5,
      Paint()..color = const Color(0x44B8B0A0),
    );
  }

  static void _drawLicensePlate(Canvas canvas, Offset pos) {
    final rect = Rect.fromLTWH(pos.dx, pos.dy, 10, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(1)),
      Paint()..color = const Color(0xFFE8E0D0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(1)),
      Paint()
        ..color = const Color(0xFF4A4440)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
    // Plate text (two lines for realism)
    canvas.drawLine(
      Offset(pos.dx + 2, pos.dy + 1.8),
      Offset(pos.dx + 8, pos.dy + 1.8),
      Paint()
        ..color = const Color(0xFF2A2420)
        ..strokeWidth = 0.6,
    );
    canvas.drawLine(
      Offset(pos.dx + 3, pos.dy + 3.2),
      Offset(pos.dx + 7, pos.dy + 3.2),
      Paint()
        ..color = const Color(0xFF3A3430)
        ..strokeWidth = 0.5,
    );
    // Registration sticker dot
    canvas.drawCircle(Offset(pos.dx + 8.5, pos.dy + 1), 0.6, Paint()..color = const Color(0xFF2288CC));
  }

  static void _drawMudFlap(Canvas canvas, Offset pos, Color color) {
    final flap = Path()
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(pos.dx + 2, pos.dy + 4)
      ..quadraticBezierTo(pos.dx, pos.dy + 5, pos.dx - 2, pos.dy + 4)
      ..close();
    canvas.drawPath(flap, Paint()..color = color.withValues(alpha: 0.35));
  }

  static void _tireContactShadow(Canvas canvas, Offset center) {
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(0, 8), width: 14, height: 4),
      Paint()..color = const Color(0x33000000),
    );
  }
}
