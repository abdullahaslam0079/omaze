import 'dart:ui';

import 'package:omaze/game/hop/domain/domain.dart';
import 'package:omaze/game/hop/render/render_context.dart';

/// Draws particle effects.
class FxRenderer {
  const FxRenderer._();

  static void drawAll(Canvas canvas, List<FxParticle> particles, HopRenderContext ctx) {
    for (final p in particles) {
      final o = ctx.tilePos(p.x, p.z);
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: o, width: p.r * (0.7 + t), height: p.r * 0.55 * t),
        Paint()..color = p.color.withValues(alpha: t * 0.85),
      );
    }
  }
}
