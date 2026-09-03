/// A collectible gem placed on the world grid.
class Coin {
  Coin(this.lane, this.z);

  final int lane;
  final int z;
  bool taken = false;
  double pop = 0;
}
