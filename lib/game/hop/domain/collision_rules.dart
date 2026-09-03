import 'package:omaze/game/hop/domain/enums.dart';
import 'package:omaze/game/hop/domain/hop_row.dart';
import 'package:omaze/game/hop/domain/mover.dart';
import 'package:omaze/game/hop/domain/world_generator.dart';

/// Result of a death-check.
enum DeathCause { none, flattened, drowned }

/// Pure collision / hazard logic extracted from HopGame.
class CollisionRules {
  const CollisionRules._();

  /// Whether there is a tree blocking [lane] at row [z].
  static bool treeAt(int z, int lane, WorldGenerator world, int pz) {
    final row = world.getRow(z, pz);
    return row.kind == RowKind.grass && row.trees.contains(lane);
  }

  /// Check if any mover on the row is close enough for a near-miss alert.
  /// Returns `true` if a near-miss was detected.
  static bool nearMiss(HopRow row, double cx) {
    if (row.kind != RowKind.road && row.kind != RowKind.rail) return false;
    for (final car in row.movers) {
      final left = car.x + 0.08;
      final right = car.x + car.w - 0.08;
      if (cx > left && cx < right) return false;
      final edge = _minAbs((cx - left), (cx - right));
      if (edge < 0.2) return true;
    }
    return false;
  }

  /// Check if the player is dead on the current row.
  static DeathCause checkDeath({
    required HopRow row,
    required double cx,
    required double px,
    required int lanes,
    required bool floatedOffScreen,
  }) {
    if (row.kind == RowKind.road || row.kind == RowKind.rail) {
      for (final car in row.movers) {
        if (cx > car.x + 0.08 && cx < car.x + car.w - 0.08) {
          return DeathCause.flattened;
        }
      }
    }
    if (row.kind == RowKind.water) {
      var onLog = false;
      for (final log in row.movers) {
        if (cx > log.x + 0.04 && cx < log.x + log.w - 0.04) {
          onLog = true;
          break;
        }
      }
      if (!onLog || px < -0.45 || px > lanes - 0.55 || floatedOffScreen) {
        return DeathCause.drowned;
      }
    }
    return DeathCause.none;
  }

  /// Find the nearest floater (log / lily-pad) to [x] on [row].
  static Mover? nearestFloater(double x, HopRow row, {double maxDist = 0.7}) {
    final cx = x + 0.5;
    Mover? best;
    var bestD = maxDist;
    for (final log in row.movers) {
      final d = cx < log.x
          ? log.x - cx
          : cx > log.x + log.w
              ? cx - (log.x + log.w)
              : 0.0;
      if (d < bestD) {
        bestD = d;
        best = log;
      }
    }
    return best;
  }

  static double _minAbs(double a, double b) {
    final aa = a.abs();
    final bb = b.abs();
    return aa < bb ? aa : bb;
  }
}
