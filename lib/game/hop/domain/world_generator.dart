import 'dart:math' as math;
import 'dart:ui';

import 'package:omaze/game/hop/domain/coin.dart';
import 'package:omaze/game/hop/domain/enums.dart';
import 'package:omaze/game/hop/domain/hop_row.dart';
import 'package:omaze/game/hop/domain/mover.dart';

/// Pure world-generation logic extracted from HopGame.
///
/// Deterministic given the same [math.Random] seed.
class WorldGenerator {
  WorldGenerator({math.Random? rng}) : _rng = rng ?? math.Random();

  static const lanes = 11;
  static const startLane = lanes ~/ 2;

  final math.Random _rng;

  int generatedThrough = -6;
  int stripLeft = 0;
  RowKind stripKind = RowKind.grass;

  final rows = <int, HopRow>{};
  final coins = <Coin>[];

  void reset() {
    rows.clear();
    coins.clear();
    generatedThrough = -6;
    stripLeft = 0;
    stripKind = RowKind.grass;
  }

  void ensureAhead(int pz) {
    final far = math.max(18, pz + 16);
    while (generatedThrough < far) {
      generatedThrough++;
      rows[generatedThrough] = _makeRow(generatedThrough);
    }
    rows.removeWhere((key, _) => key < pz - 10);
    coins.removeWhere((c) => c.z < pz - 10);
  }

  HopRow getRow(int z, int pz) {
    ensureAhead(pz);
    return rows[z] ?? _makeRow(z);
  }

  HopRow _makeRow(int index) {
    if (index <= 2) {
      final safe = HopRow(RowKind.grass, index, 0, 0, {});
      if (index == 0) {
        safe.flowers.addAll({2, startLane + 2});
      }
      if (index == 1) {
        safe.flowers.addAll({1, 3, startLane + 3, lanes - 2});
        safe.shrooms.add(startLane);
        safe.rocks.add(2);
      }
      if (index == 2) {
        safe.crystals.add(startLane - 1);
        safe.flowers.addAll({startLane + 2, 1});
        safe.shrooms.add(lanes - 3);
      }
      return safe;
    }

    if (stripLeft <= 0) {
      final roll = _rng.nextDouble();
      if (index <= 6) {
        stripKind = roll < 0.45 ? RowKind.road : RowKind.grass;
        stripLeft = 1;
      } else if (index > 12 && roll < 0.12) {
        stripKind = RowKind.rail;
        stripLeft = 1;
      } else if (roll < 0.4) {
        stripKind = RowKind.road;
        stripLeft = 1 + _rng.nextInt(index > 18 ? 3 : 2);
      } else if (roll < 0.68) {
        stripKind = RowKind.water;
        stripLeft = 1 + _rng.nextInt(2);
      } else {
        stripKind = RowKind.grass;
        stripLeft = 1 + _rng.nextInt(2);
      }
    }
    stripLeft--;

    final dir = _rng.nextBool() ? 1 : -1;
    final speed = switch (stripKind) {
      RowKind.road => math.min(2.15, 0.72 + index * 0.012 + _rng.nextDouble() * 0.32),
      RowKind.water => math.min(1.42, 0.62 + index * 0.01 + _rng.nextDouble() * 0.24),
      RowKind.rail => 3.2 + index * 0.016 + _rng.nextDouble() * 0.7,
      RowKind.grass => 0.0,
    };

    final trees = <int>{};
    if (stripKind == RowKind.grass) {
      final count = 2 + _rng.nextInt(2);
      while (trees.length < count) {
        trees.add(_rng.nextInt(lanes));
      }
      if (trees.length > lanes - 4) {
        trees.remove(trees.first);
      }
    }

    final pads = stripKind == RowKind.water && _rng.nextDouble() < 0.38;
    final row = HopRow(stripKind, index, dir, speed, trees, pads: pads);

    if (stripKind == RowKind.grass) {
      for (var i = 0; i < lanes; i++) {
        if (trees.contains(i)) continue;
        final roll = _rng.nextDouble();
        if (roll < 0.32) {
          row.flowers.add(i);
        } else if (roll < 0.42) {
          row.shrooms.add(i);
        } else if (roll < 0.48) {
          row.crystals.add(i);
        } else if (roll < 0.58) {
          row.rocks.add(i);
        }
      }
      if (index > 2 && _rng.nextDouble() < 0.34) {
        final lane = _rng.nextInt(lanes);
        if (!trees.contains(lane)) {
          coins.add(Coin(lane, index));
        }
      }
    }

    if (stripKind == RowKind.road) {
      final n = index > 16 && _rng.nextDouble() < 0.42 ? 3 : 2;
      for (var i = 0; i < n; i++) {
        final truck = _rng.nextDouble() < 0.28;
        row.movers.add(
          Mover(
            i * (lanes / n) + _rng.nextDouble() * 1.05,
            truck ? 1.45 + _rng.nextDouble() * 0.25 : 0.88 + _rng.nextDouble() * 0.28,
            _carColor(),
            truck: truck,
          ),
        );
      }
    } else if (stripKind == RowKind.water) {
      final n = pads ? 5 : 4 + _rng.nextInt(2);
      for (var i = 0; i < n; i++) {
        row.movers.add(
          Mover(
            i * (lanes / n) + _rng.nextDouble() * 0.35,
            pads ? 0.92 + _rng.nextDouble() * 0.18 : 1.32 + _rng.nextDouble() * 0.32,
            pads ? const Color(0xFF3FAE4A) : const Color(0xFF8B5A2B),
          ),
        );
      }
    } else if (stripKind == RowKind.rail) {
      row.movers.add(
        Mover(
          dir > 0 ? -14.0 - _rng.nextDouble() * 8 : lanes + 14 + _rng.nextDouble() * 8,
          7.5 + _rng.nextDouble() * 2,
          const Color(0xFFD24B3A),
          train: true,
        ),
      );
    }
    return row;
  }

  Color _carColor() {
    const colors = [
      Color(0xFFC45C6A),
      Color(0xFF5B6BD9),
      Color(0xFFE0B14A),
      Color(0xFF2F2A3A),
      Color(0xFF4AAE7A),
      Color(0xFFD46A3A),
      Color(0xFF8A5AD0),
      Color(0xFFF3E6C8),
    ];
    return colors[_rng.nextInt(colors.length)];
  }
}
