import 'dart:ui';

import 'package:omaze/game/chick.dart';
import 'package:omaze/game/hop/domain/domain.dart';
import 'package:omaze/game/hop/render/render_context.dart';
import 'package:omaze/game/hop/render/river_renderer.dart';

/// Data needed to render the player.
class PlayerRenderData {
  const PlayerRenderData({
    required this.phase,
    required this.px,
    required this.pz,
    required this.fromX,
    required this.fromZ,
    required this.hopT,
    required this.hopMove,
    required this.hopPeak,
    required this.hopLift,
    required this.along,
    required this.squash,
    required this.splash,
    required this.flattened,
    required this.face,
    required this.chick,
    required this.ridingCurrent,
    required this.rideLog,
    required this.waryDir,
  });

  final HopPhase phase;
  final double px;
  final int pz;
  final double fromX;
  final int fromZ;
  final double hopT;
  final HopMove hopMove;
  final double hopPeak;
  final double hopLift;
  final double along;
  final double squash;
  final double splash;
  final bool flattened;
  final int face;
  final ChickAnim chick;
  final bool ridingCurrent;
  final Mover? rideLog;
  final int waryDir;
}

/// Draws the chick player character.
class PlayerRenderer {
  const PlayerRenderer._();

  static void draw(Canvas canvas, PlayerRenderData data, HopRenderContext ctx, HopRow Function(int) getRow) {
    if (data.phase == HopPhase.dead && data.splash > 0) {
      final p = ctx.tilePos(data.px + 0.5, data.pz + 0.22);
      ctx.glow(canvas, p, 16 + (1 - data.splash) * 10, Color.fromRGBO(180, 240, 250, data.splash * 0.4));
      canvas.drawCircle(p, 12 + (1 - data.splash) * 18, Paint()..color = Color.fromRGBO(220, 250, 255, data.splash * 0.4));
      return;
    }

    final walking = data.hopMove == HopMove.step;
    final u = data.hopT >= 1 ? 1.0 : data.hopT;
    final ease = data.along;
    final x = data.fromX + (data.px - data.fromX) * ease;
    final z = data.fromZ + (data.pz - data.fromZ) * ease;
    final hop = data.flattened || walking ? 0.0 : data.hopLift;
    final riding = data.ridingCurrent && !data.flattened;
    final rideRow = riding ? getRow(data.pz) : null;
    final leaf = rideRow?.pads ?? false;
    final rideX = data.rideLog?.x ?? x;
    final bob = riding ? RiverRenderer.floaterBob(rideX, data.pz, ctx.time, leaf: leaf) : 0.0;
    final roll = riding ? RiverRenderer.floaterRoll(rideX, data.pz, ctx.time, leaf: leaf) : 0.0;
    final driftLean = rideRow == null ? 0.0 : rideRow.dir * 2.6 + roll * 28;
    final p = ctx.tilePos(x + 0.5, z + 0.22) + Offset(driftLean, bob);
    final c = Offset(p.dx, p.dy - hop);
    if (rideRow != null) {
      RiverRenderer.drawRideRipple(canvas, p, rideRow, ctx);
    }
    ChickPainter.paint(
      canvas,
      ChickDraw(
        ground: p,
        center: c,
        pose: data.chick.pose,
        frame: data.chick.frameIndex,
        face: rideRow != null && data.face == 0 ? rideRow.dir : data.face,
        hopLift: hop,
        hopPeak: data.hopPeak,
        progress: u,
        squash: data.squash,
        flattened: data.flattened,
        blink: data.chick.blink > 0 && data.chick.pose == ChickPose.idle,
        time: ctx.time,
        react: (data.chick.bumpT / ChickAnim.bumpDur).clamp(0.0, 1.0),
        startle: data.chick.startleT > 0,
        wary: data.waryDir,
      ),
    );
  }
}
