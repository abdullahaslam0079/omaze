import 'package:omaze/game/hop/domain/coin.dart';

/// Pure scoring logic.
class ScoringRules {
  const ScoringRules._();

  /// Try to collect coins at [pz] / [lane].
  /// Returns the list of newly collected coins.
  static List<Coin> collect(List<Coin> coins, int pz, double px) {
    final collected = <Coin>[];
    for (final coin in coins) {
      if (coin.taken || coin.z != pz) continue;
      if ((px.round() - coin.lane).abs() == 0) {
        coin.taken = true;
        collected.add(coin);
      }
    }
    return collected;
  }

  /// Compute score = max-row + loot.
  static int computeScore(int maxZ, int loot) => maxZ + loot;
}
