import 'dart:ui';

/// A short-lived visual particle effect.
class FxParticle {
  FxParticle(
    this.x,
    this.z,
    this.vx,
    this.vz,
    this.life,
    this.color,
    this.r, {
    this.gravity = 0,
  }) : maxLife = life;

  double x;
  double z;
  double vx;
  double vz;
  double life;
  final double maxLife;
  Color color;
  double r;
  double gravity;
}
