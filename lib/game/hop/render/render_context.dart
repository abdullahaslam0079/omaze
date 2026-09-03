import 'dart:math' as math;
import 'dart:ui';

import 'package:omaze/game/hop/domain/domain.dart';

/// Shared rendering state passed to all renderers.
///
/// Avoids tight coupling between renderers and HopGame fields.
class HopRenderContext {
  const HopRenderContext({
    required this.size,
    required this.tile,
    required this.ground,
    required this.horizon,
    required this.cam,
    required this.camX,
    required this.time,
    required this.shake,
    required this.rows,
  });

  final Size size;
  final double tile;
  final double ground;
  final double horizon;
  final double cam;
  final double camX;
  final double time;
  final double shake;
  final Map<int, HopRow> rows;

  /// Convert world coordinates to screen position.
  Offset tilePos(double x, double z) {
    return Offset(
      (x - camX) * tile + size.width * 0.5 + math.sin(shake * 28) * shake * 6,
      ground - (z * tile - cam),
    );
  }

  /// Shared meadow wind. Positive values bend toward the right.
  double wind(double x, double z, {double amp = 1}) {
    return (math.sin(time * 1.08 + x * 0.38 + z * 0.21) * 1.85 +
            math.sin(time * 2.22 + x * 0.91) * 0.55) *
        amp;
  }

  /// Draw a soft glow circle.
  void glow(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
}
