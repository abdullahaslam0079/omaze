import 'dart:ui';

/// A moving entity on a row (car, truck, log, lily-pad, or train).
class Mover {
  Mover(
    this.x,
    this.w,
    this.color, {
    this.truck = false,
    this.train = false,
  });

  double x;
  double w;
  Color color;
  bool truck;
  bool train;
}
