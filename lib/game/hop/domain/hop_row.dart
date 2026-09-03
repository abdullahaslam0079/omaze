import 'package:omaze/game/hop/domain/enums.dart';
import 'package:omaze/game/hop/domain/mover.dart';

/// A single horizontal row in the world grid.
class HopRow {
  HopRow(
    this.kind,
    this.index,
    this.dir,
    this.speed,
    this.trees, {
    this.pads = false,
  });

  final RowKind kind;
  final int index;
  final int dir;
  final double speed;
  final Set<int> trees;
  final Set<int> flowers = {};
  final Set<int> rocks = {};
  final Set<int> shrooms = {};
  final Set<int> crystals = {};
  final bool pads;
  final movers = <Mover>[];
}
