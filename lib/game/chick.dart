import 'dart:math' as math;
import 'dart:ui';

enum ChickPose { idle, walk, run, jump, fall, land, hurt, collect, bump }

enum _Mood { calm, walk, effort, joy, focus, land, happy, hurt, dizzy, wary, startle }

class ChickFrames {
  static const idle = 5;
  static const walk = 6;
  static const run = 6;
  static const jump = 3;
  static const fall = 3;
  static const land = 2;
  static const hurt = 1;
  static const collect = 1;

  static const idleStep = 0.18;
  static const walkStep = 0.08;
  static const runStep = 0.06;
  static const jumpStep = 0.08;
  static const fallStep = 0.08;
  static const landStep = 0.08;

  static int count(ChickPose pose) => switch (pose) {
        ChickPose.idle => idle,
        ChickPose.walk => walk,
        ChickPose.run => run,
        ChickPose.jump => jump,
        ChickPose.fall => fall,
        ChickPose.land => land,
        ChickPose.hurt => hurt,
        ChickPose.collect => collect,
        ChickPose.bump => 1,
      };

  static double step(ChickPose pose) => switch (pose) {
        ChickPose.idle => idleStep,
        ChickPose.walk => walkStep,
        ChickPose.run => runStep,
        ChickPose.jump => jumpStep,
        ChickPose.fall => fallStep,
        ChickPose.land => landStep,
        ChickPose.hurt => 1,
        ChickPose.collect => 1,
        ChickPose.bump => 1,
      };
}

class ChickAnim {
  ChickPose pose = ChickPose.idle;
  double frame = 0;
  double blink = 0;
  double collectT = 0;
  double bumpT = 0;
  double startleT = 0;
  double _blinkWait = 2.4;

  static const bumpDur = 0.48;
  static const startleDur = 0.34;

  int get frameIndex => frame.floor().clamp(0, ChickFrames.count(pose) - 1);

  void playCollect() {
    if (bumpT > 0) {
      return;
    }
    collectT = 0.38;
    pose = ChickPose.collect;
    frame = 0;
  }

  void playBump() {
    bumpT = bumpDur;
    startleT = 0;
    collectT = 0;
    pose = ChickPose.bump;
    frame = 0;
  }

  void playStartle() {
    if (bumpT > 0 || collectT > 0) {
      return;
    }
    startleT = startleDur;
  }

  void reset() {
    pose = ChickPose.idle;
    frame = 0;
    blink = 0;
    collectT = 0;
    bumpT = 0;
    startleT = 0;
    _blinkWait = 2.2;
  }

  void update(double dt, ChickPose next, math.Random rng) {
    collectT = math.max(0, collectT - dt);
    bumpT = math.max(0, bumpT - dt);
    startleT = math.max(0, startleT - dt);
    blink = math.max(0, blink - dt);
    _blinkWait -= dt;
    if (blink <= 0 && _blinkWait <= 0) {
      blink = 0.12;
      _blinkWait = 1.8 + rng.nextDouble() * 2.4;
    }

    final resolved = bumpT > 0
        ? ChickPose.bump
        : collectT > 0
            ? ChickPose.collect
            : next;
    if (resolved != pose) {
      pose = resolved;
      frame = 0;
    } else {
      frame += dt / ChickFrames.step(pose);
      final max = ChickFrames.count(pose).toDouble();
      if (frame >= max) {
        frame = pose == ChickPose.idle || pose == ChickPose.walk || pose == ChickPose.run
            ? frame % max
            : max - 0.001;
      }
    }
  }
}

class ChickDraw {
  const ChickDraw({
    required this.ground,
    required this.center,
    required this.pose,
    required this.frame,
    required this.face,
    required this.hopLift,
    required this.hopPeak,
    required this.progress,
    required this.squash,
    required this.flattened,
    required this.blink,
    required this.time,
    this.react = 0,
    this.startle = false,
    this.wary = 0,
  });

  final Offset ground;
  final Offset center;
  final ChickPose pose;
  final int frame;
  final int face;
  final double hopLift;
  final double hopPeak;
  final double progress;
  final double squash;
  final bool flattened;
  final bool blink;
  final double time;
  final double react;
  final bool startle;
  final int wary;
}

class _Walk {
  _Walk._(this.t, this.leftSwing);

  factory _Walk.of(double progress) {
    final p = progress.clamp(0.0, 1.0);
    final two = p * 2;
    return _Walk._(two % 1.0, two < 1);
  }

  final double t;
  final bool leftSwing;

  double get _swing {
    const hold = 0.11;
    if (t <= hold) {
      return 0;
    }
    return ((t - hold) / (1 - hold)).clamp(0.0, 1.0);
  }

  double get lift {
    final u = _swing;
    if (u <= 0) {
      return 0;
    }
    const peak = 0.38;
    if (u < peak) {
      final s = math.sin((u / peak) * math.pi * 0.5);
      return s * s;
    }
    final s = math.cos(((u - peak) / (1 - peak)) * math.pi * 0.5);
    return s * s;
  }

  double get reach {
    final u = _swing;
    final e = u * u * (3 - 2 * u);
    final over = u > 0.70 ? math.sin((u - 0.70) / 0.30 * math.pi) * 0.10 : 0.0;
    return e * 2 - 1 + over;
  }

  double get stanceX => -reach;
  double get swingX => reach;

  double get strike {
    if (t > 0.86) {
      return ((t - 0.86) / 0.14).clamp(0.0, 1.0);
    }
    if (t < 0.14) {
      return 1 - t / 0.14;
    }
    return 0;
  }

  double get settle {
    if (t < 0.10 || t > 0.30) {
      return 0;
    }
    return math.sin((t - 0.10) / 0.20 * math.pi) * 0.65;
  }

  double get stanceLoad => (1 - lift) * 0.7 + strike * 0.3;

  double get hip {
    final side = leftSwing ? 1.0 : -1.0;
    return side * (0.28 + 0.72 * (1 - follow(0.07)));
  }

  double get swingToe => (0.50 - _swing) * 1.15;
  double get stanceToe => (t - 0.20) * 0.52;

  double get bob => lift * 2.35 - strike * 1.55 + settle;
  double get lean => 0.08 + lift * 0.04 + strike * 0.045;
  double get nod => strike * 1.55 - lift * 0.3 - settle * 0.25;

  double follow([double lag = 0.14]) {
    final u = ((t - lag) % 1.0 + 1.0) % 1.0;
    final s = math.sin(u * math.pi);
    return s * s;
  }
}

class ChickPainter {
  ChickPainter._();

  static final _body = Paint()..color = const Color(0xFFFFF6E8);
  static final _shade = Paint()..color = const Color(0xFFE8D2B0);
  static final _wingSoft = Paint()..color = const Color(0xFFF0D9B4);
  static final _volume = Paint()..color = const Color(0x2EC9A07A);
  static final _belly = Paint()..color = const Color(0x28E0B888);
  static final _cheek = Paint()..color = const Color(0x88F0A090);
  static final _petal = Paint()..color = const Color(0xFFF6E27A);
  static final _pistil = Paint()..color = const Color(0xFFC46A18);
  static final _comb = Paint()..color = const Color(0xFFE23B3B);
  static final _combDark = Paint()..color = const Color(0xFFC92F2F);
  static final _gold = Paint()..color = const Color(0xFFF4C542);
  static final _beak = Paint()..color = const Color(0xFFF29A2E);
  static final _beakShade = Paint()..color = const Color(0x88C46A18);
  static final _beakLine = Paint()
    ..color = const Color(0x88C46A18)
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  static final _footPaint = Paint()..color = const Color(0xFFF29A2E);
  static final _toe = Paint()
    ..color = const Color(0xFFE07A20)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  static final _eyeWhite = Paint()..color = const Color(0xFFFFFFFF);
  static final _eye = Paint()..color = const Color(0xFF1A1A1A);
  static final _shine = Paint()..color = const Color(0xFFFFFFFF);
  static final _lid = Paint()
    ..color = const Color(0xFF4A2C3A)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final _highlight = Paint()..color = const Color(0x55FFFFFF);
  static final _shadow = Paint();
  static final _glow = Paint()
    ..color = const Color(0x28F4C542)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
  static final _spark = Paint()
    ..color = const Color(0xFFF6E27A)
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  static final _sweat = Paint()..color = const Color(0xAA8EC8F0);
  static final _brow = Paint()
    ..color = const Color(0xFF4A2C3A)
    ..strokeWidth = 1.35
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final _beakFrontPath = Path()
    ..moveTo(-3.0, 1.6)
    ..quadraticBezierTo(0, 7.2, 3.0, 1.6)
    ..close();
  static final _beakSidePath = Path()
    ..moveTo(12, -2.6)
    ..lineTo(20.5, 0.4)
    ..lineTo(12, 3.6)
    ..close();

  static final Path _frontEgg = Path()
    ..moveTo(0, -15.5)
    ..cubicTo(9.5, -16.2, 14.8, -8, 15.2, 1)
    ..cubicTo(15.6, 10.5, 9.5, 15.2, 0, 15.2)
    ..cubicTo(-9.5, 15.2, -15.6, 10.5, -15.2, 1)
    ..cubicTo(-14.8, -8, -9.5, -16.2, 0, -15.5)
    ..close();

  static final Path _sideEgg = Path()
    ..moveTo(-15, -6)
    ..cubicTo(-15, -16, -4, -17, 6, -14)
    ..cubicTo(16, -11, 18, -2, 16, 6)
    ..cubicTo(14, 14, 4, 16, -6, 14)
    ..cubicTo(-16, 12, -18, 4, -15, -6)
    ..close();

  static void paint(Canvas canvas, ChickDraw d) {
    final air = d.hopPeak <= 0 ? 0.0 : (d.hopLift / d.hopPeak).clamp(0.0, 1.0);
    if (d.pose == ChickPose.walk && !d.flattened) {
      final w = _Walk.of(d.progress);
      final planted = d.face == 0 ? (w.leftSwing ? 3.6 : -3.6) : d.face * w.stanceX * 5.0;
      _shadow.color = Color.fromRGBO(0, 0, 0, 0.24 + 0.08 * w.stanceLoad);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(d.ground.dx + planted, d.ground.dy + 13),
          width: 19 + 7 * w.stanceLoad,
          height: 6.6 + 0.8 * w.stanceLoad,
        ),
        _shadow,
      );
    } else {
      _shadow.color = Color.fromRGBO(0, 0, 0, 0.24 * (1 - air * 0.55));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(d.ground.dx, d.ground.dy + 13),
          width: 24 * (1 - air * 0.42),
          height: 7.5,
        ),
        _shadow,
      );
    }

    if (!d.flattened && d.pose != ChickPose.hurt) {
      canvas.drawCircle(d.center, 17, _glow);
    }

    var sx = 1.0;
    var sy = 1.0;
    var rot = 0.0;
    if (d.pose == ChickPose.idle && !d.flattened) {
      sy *= 1 + math.sin(d.time * 3.2) * 0.018;
    }
    if (d.flattened) {
      sx *= 1.32;
      sy *= 0.38;
    } else if (d.pose == ChickPose.bump) {
      final hit = d.react.clamp(0.0, 1.0);
      sx *= 1 + 0.16 * hit;
      sy *= 1 - 0.12 * hit;
      rot = d.face != 0 ? -d.face * 0.34 * hit : 0.18 * hit;
      rot += math.sin(d.time * 26) * 0.10 * hit;
    } else if (d.progress < 1) {
      final p = d.progress;
      final arc = math.sin(p * math.pi);
      final stepping = d.pose == ChickPose.walk;
      final leap = d.hopPeak > 30;
      if (stepping) {
        final w = _Walk.of(p);
        sx *= 1 + 0.07 * w.strike;
        sy *= 1 - 0.08 * w.strike;
        rot = d.face * w.lean + (d.face == 0 ? -w.hip * 0.055 : 0);
      } else if (p < 0.08) {
        final k = 1 - p / 0.08;
        sx *= 1 + (leap ? 0.18 : 0.14) * k;
        sy *= 1 - (leap ? 0.16 : 0.12) * k;
      } else if (p < 0.5) {
        sx *= leap ? 0.90 : 0.94;
        sy *= leap ? 1.16 : 1.10;
      } else if (p < 0.82) {
        sx *= leap ? 0.94 : 0.97;
        sy *= leap ? 1.10 : 1.06;
      } else {
        final k = (p - 0.82) / 0.18;
        sx *= 1 + (leap ? 0.22 : 0.16) * k;
        sy *= 1 - (leap ? 0.18 : 0.14) * k;
      }
      if (!stepping) {
        rot = d.face != 0 ? d.face * 0.22 * arc : (p < 0.5 ? -0.10 : 0.14) * arc;
        if (leap) {
          rot *= 1.25;
        }
      }
    } else if (d.pose == ChickPose.land) {
      sx *= 1 + d.squash * 0.22;
      sy *= 1 - d.squash * 0.2;
    } else if (d.squash.abs() > 0.04) {
      sx *= 1 + d.squash * 0.16;
      sy *= 1 - d.squash * 0.14;
    } else if (d.pose == ChickPose.hurt) {
      sx *= 1.12;
      sy *= 0.78;
    } else if (d.pose == ChickPose.collect) {
      sx *= 1.04;
      sy *= 1.04;
    }

    var recoilX = 0.0;
    var recoilY = 0.0;
    if (d.pose == ChickPose.bump) {
      final hit = d.react.clamp(0.0, 1.0);
      recoilX = d.face == 0 ? math.sin(d.time * 22) * 1.6 * hit : -d.face * 7.5 * hit;
      recoilY = (d.face == 0 ? 6.5 : 2.2) * hit;
    }

    canvas.save();
    canvas.translate(d.center.dx + recoilX, d.center.dy + recoilY);
    canvas.rotate(rot);
    canvas.scale(d.face < 0 ? -sx : sx, sy);
    if (d.face == 0) {
      _front(canvas, d);
    } else {
      _side(canvas, d);
    }
    canvas.restore();

    if (d.pose == ChickPose.collect) {
      _sparkles(canvas, d.center, d.time);
    } else if (d.pose == ChickPose.bump) {
      _bumpStars(canvas, Offset(d.center.dx + recoilX, d.center.dy + recoilY - 8), d.time, d.react);
    }
  }

  static double _bob(ChickDraw d) {
    if (d.flattened || d.pose == ChickPose.hurt) {
      return 0;
    }
    return switch (d.pose) {
      ChickPose.idle => math.sin(d.time * 3.2) * 1.4,
      ChickPose.walk => _Walk.of(d.progress).bob,
      ChickPose.run => math.sin(d.frame * 1.4 + d.time * 11) * 2.0,
      ChickPose.land => d.squash * 1.6,
      ChickPose.collect => math.sin(d.time * 16) * 1.6,
      ChickPose.bump => 1.4 * d.react,
      _ => 0,
    };
  }

  static void _front(Canvas canvas, ChickDraw d) {
    final bob = _bob(d);
    final air = d.progress < 1 && !d.flattened;
    final stepping = d.pose == ChickPose.walk;
    final w = _Walk.of(d.progress);
    final mood = _mood(d);
    final look = switch (mood) {
      _Mood.calm => math.sin(d.time * 0.85) * 0.7,
      _Mood.walk => w.hip * 0.22,
      _Mood.wary => (d.wary == 2 || d.wary == 3) ? 0.0 : d.wary.toDouble() * 0.9,
      _Mood.startle => 0.0,
      _Mood.dizzy => math.sin(d.time * 18) * 0.4,
      _ => air && !stepping ? (d.progress < 0.5 ? -0.4 : 0.5) : 0.0,
    };
    final lookY = switch (mood) {
      _Mood.wary when d.wary == 2 => -1.3,
      _Mood.wary when d.wary == 3 => 1.2,
      _Mood.dizzy => 0.5,
      _ => 0.0,
    };
    final combSway = d.pose == ChickPose.idle
        ? math.sin(d.time * 3.2) * 0.5 + (d.wary == 2 ? 0.6 : 0)
        : stepping
            ? w.follow(0.2) * 1.6 - 0.8 + w.nod * 0.25
            : mood == _Mood.dizzy
                ? math.sin(d.time * 20) * 2.2
                : (air ? math.sin(d.progress * math.pi) * 1.2 : 0.0);
    final wingL = stepping ? 0.06 + (w.leftSwing ? w.lift * 0.08 : w.lift * 0.4) : 0.0;
    final wingR = stepping ? 0.06 + (w.leftSwing ? w.lift * 0.4 : w.lift * 0.08) : 0.0;
    final wing = stepping
        ? 0.0
        : air
            ? math.sin(d.progress * math.pi) * (d.hopPeak > 30 ? 0.95 : 0.78)
            : switch (d.pose) {
                ChickPose.collect => 0.62,
                ChickPose.bump => 0.55 + d.react * 0.25,
                ChickPose.idle => math.sin(d.time * 3.2) * 0.1,
                _ => 0.06,
              };
    final liftFeet = air && !stepping && d.progress > 0.08 && d.progress < 0.88;

    canvas.save();
    canvas.translate(0, bob);

    if (stepping && !d.flattened) {
      _walkFeetFront(canvas, d.progress);
    } else if (!liftFeet && !d.flattened) {
      _footPair(canvas, 0, 1.4);
    } else if (liftFeet) {
      _tuckedFeet(canvas);
    }

    canvas.save();
    if (stepping) {
      canvas.translate(w.hip * 2.6, w.nod * 0.2);
    }

    if (stepping) {
      _wing(canvas, -1, wingL);
      _wing(canvas, 1, wingR);
    } else {
      _wing(canvas, -1, wing);
      _wing(canvas, 1, wing);
    }

    canvas.drawPath(_frontEgg, _body);
    canvas.save();
    canvas.clipPath(_frontEgg);
    canvas.drawOval(const Rect.fromLTWH(1, -1, 14, 16), _volume);
    canvas.drawOval(const Rect.fromLTWH(-11, -13, 12, 9), _highlight);
    canvas.drawOval(const Rect.fromLTWH(-8, 3, 16, 10), _belly);
    canvas.restore();
    canvas.drawCircle(Offset(-6.2, 0.6 + (stepping ? w.strike * 0.35 : 0)), 2.8, _cheek);
    canvas.drawCircle(Offset(6.2, 0.6 + (stepping ? w.strike * 0.35 : 0)), 2.8, _cheek);

    canvas.save();
    canvas.translate(combSway, stepping ? w.nod * 0.15 : 0);
    _combFront(canvas);
    _flower(
      canvas,
      Offset(-6.4 + (stepping ? w.follow(0.26) * 0.5 - 0.25 : 0), -14.2 + (stepping ? w.nod * 0.08 : 0)),
    );
    canvas.restore();

    final eye = Offset(-4.8 + look, -4.6 + lookY + (stepping ? w.nod * 0.12 : 0));
    final eyeR = Offset(4.8 + look, -4.6 + lookY + (stepping ? w.nod * 0.12 : 0));
    _faceEyes(canvas, d, mood, eye, eyeR, look);
    _beakFront(canvas, open: mood == _Mood.dizzy);
    if (mood == _Mood.dizzy || mood == _Mood.wary || mood == _Mood.startle) {
      _sweatDrop(canvas, const Offset(11.5, -8), d.time);
    }
    canvas.restore();
    canvas.restore();
  }

  static void _side(Canvas canvas, ChickDraw d) {
    final bob = _bob(d);
    final air = d.progress < 1 && !d.flattened;
    final stepping = d.pose == ChickPose.walk;
    final w = _Walk.of(d.progress);
    final mood = _mood(d);
    final look = switch (mood) {
      _Mood.calm => math.sin(d.time * 0.85) * 0.5,
      _Mood.walk => w.nod * 0.08,
      _Mood.wary => d.wary == 2 ? 0.3 : 0.0,
      _Mood.dizzy => math.sin(d.time * 18) * 0.35,
      _ => 0.0,
    };
    final lookY = switch (mood) {
      _Mood.wary when d.wary == 2 => -1.1,
      _Mood.wary when d.wary == 3 => 1.0,
      _Mood.dizzy => 0.4,
      _ => stepping ? w.nod * 0.14 : 0.0,
    };
    final wing = stepping
        ? 0.08 + w.follow(0.12) * 0.48
        : air
            ? math.sin(d.progress * math.pi) * (d.hopPeak > 30 ? 1.0 : 0.82)
            : mood == _Mood.dizzy
                ? 0.55 + d.react * 0.2
                : 0.16 + math.sin(d.time * 8) * 0.09;
    final liftFeet = air && !stepping && d.progress > 0.08 && d.progress < 0.88;

    canvas.save();
    canvas.translate(0, bob);
    canvas.drawOval(
      Rect.fromLTWH(-20, 1.0 + (stepping ? w.follow(0.22) * 3.0 - w.strike * 1.2 : 0), 11, 8),
      _shade,
    );
    if (stepping && !d.flattened) {
      _walkFeetSide(canvas, d.progress);
    } else if (!liftFeet && !d.flattened) {
      _foot(canvas, const Offset(3, 14));
    } else if (liftFeet) {
      _foot(canvas, const Offset(4, 9));
    }

    canvas.save();
    canvas.translate(-6 - (stepping ? w.follow(0.18) * 0.8 : 0), 2 + (stepping ? w.nod * 0.15 : 0));
    canvas.rotate(-0.28 - wing);
    canvas.drawOval(const Rect.fromLTWH(-11, -5, 16, 10), _wingSoft);
    canvas.drawOval(const Rect.fromLTWH(-8, -2, 11, 6), _shade);
    canvas.restore();

    canvas.save();
    if (stepping) {
      canvas.translate(w.reach * 0.9, w.nod * 0.18);
    }
    canvas.drawPath(_sideEgg, _body);
    canvas.save();
    canvas.clipPath(_sideEgg);
    canvas.drawOval(const Rect.fromLTWH(2, -2, 14, 14), _volume);
    canvas.drawOval(const Rect.fromLTWH(-5, -13, 11, 8), _highlight);
    canvas.drawOval(const Rect.fromLTWH(-5, 3, 13, 9), _belly);
    canvas.restore();
    canvas.drawCircle(Offset(8.4, -0.4 + (stepping ? w.strike * 0.3 : 0)), 2.6, _cheek);

    canvas.drawCircle(Offset(0.2, -15.2 - (stepping ? w.nod * 0.2 : 0) + (mood == _Mood.dizzy ? math.sin(d.time * 20) * 0.8 : 0)), 3.8, _comb);
    canvas.drawCircle(Offset(5.4 + (stepping ? w.follow(0.18) * 1.4 - 0.7 : 0) + (mood == _Mood.dizzy ? math.sin(d.time * 18) * 1.2 : 0), -14.4 - (stepping ? w.nod * 0.25 : 0)), 3.1, _combDark);
    canvas.drawCircle(const Offset(2.6, -17.6), 2.0, _gold);
    canvas.drawCircle(const Offset(-0.2, -16.8), 1.0, _shine);
    _flower(
      canvas,
      Offset(-5.2 + (stepping ? w.follow(0.28) * 0.7 - 0.35 : 0), -13.4 + (stepping ? w.nod * 0.1 : 0)),
    );

    final eye = Offset(6.4 + look, -4.4 + lookY);
    _faceEyes(canvas, d, mood, eye, null, look);
    if (mood == _Mood.dizzy) {
      canvas.drawOval(const Rect.fromLTWH(12.2, -1.2, 8.2, 5.4), _beak);
      canvas.drawOval(const Rect.fromLTWH(14.4, 0.4, 3.6, 2.4), _beakShade);
    } else {
      canvas.drawPath(_beakSidePath, _beak);
    }
    if (mood == _Mood.dizzy || mood == _Mood.wary || mood == _Mood.startle) {
      _sweatDrop(canvas, const Offset(2.5, -9), d.time);
    }
    canvas.restore();
    canvas.restore();
  }

  static _Mood _mood(ChickDraw d) {
    if (d.flattened || d.pose == ChickPose.hurt) {
      return _Mood.hurt;
    }
    if (d.pose == ChickPose.bump) {
      return _Mood.dizzy;
    }
    if (d.pose == ChickPose.collect) {
      return _Mood.happy;
    }
    if (d.startle) {
      return _Mood.startle;
    }
    if (d.pose == ChickPose.walk) {
      return _Mood.walk;
    }
    if (d.wary != 0) {
      return _Mood.wary;
    }
    return _Mood.calm;
  }

  static void _combFront(Canvas canvas) {
    canvas.drawCircle(const Offset(-3.6, -15.4), 3.6, _comb);
    canvas.drawCircle(const Offset(0, -17.2), 3.3, _comb);
    canvas.drawCircle(const Offset(3.6, -15.2), 3.2, _combDark);
    canvas.drawCircle(const Offset(-4.2, -17.2), 1.05, _shine);
  }

  static void _flower(Canvas canvas, Offset p) {
    for (var i = 0; i < 5; i++) {
      final a = i * 1.2566;
      canvas.drawCircle(p + Offset(math.cos(a) * 2.15, math.sin(a) * 2.15), 1.45, _petal);
    }
    canvas.drawCircle(p, 1.15, _pistil);
    canvas.drawCircle(p + const Offset(0.35, -0.35), 0.4, _shine);
  }

  static void _sparkles(Canvas canvas, Offset c, double time) {
    for (var i = 0; i < 3; i++) {
      final a = time * 8 + i * 2.1;
      final p = c + Offset(math.cos(a) * 13, -20 + math.sin(a * 1.4) * 4);
      canvas.drawLine(p + const Offset(-2.4, 0), p + const Offset(2.4, 0), _spark);
      canvas.drawLine(p + const Offset(0, -2.4), p + const Offset(0, 2.4), _spark);
    }
  }

  static void _bumpStars(Canvas canvas, Offset c, double time, double react) {
    final a = react.clamp(0.0, 1.0);
    if (a <= 0) {
      return;
    }
    for (var i = 0; i < 3; i++) {
      final ang = time * 9 + i * 2.094;
      final p = c + Offset(math.cos(ang) * 16, math.sin(ang) * 7 - 4);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(ang);
      canvas.scale(0.55 + 0.55 * a);
      canvas.drawLine(const Offset(-2.6, 0), const Offset(2.6, 0), _spark);
      canvas.drawLine(const Offset(0, -2.6), const Offset(0, 2.6), _spark);
      canvas.restore();
    }
  }

  static void _sweatDrop(Canvas canvas, Offset p, double time) {
    final bob = math.sin(time * 14) * 0.6;
    canvas.drawOval(Rect.fromCenter(center: p + Offset(0, bob), width: 2.4, height: 3.4), _sweat);
    canvas.drawCircle(p + Offset(0.4, -0.6 + bob), 0.5, _shine);
  }

  static void _faceEyes(Canvas canvas, ChickDraw d, _Mood mood, Offset a, Offset? b, double look) {
    switch (mood) {
      case _Mood.happy:
      case _Mood.joy:
        _happyEyes(canvas, a, b);
      case _Mood.hurt:
        _hurtEyes(canvas, a, b);
      case _Mood.dizzy:
        _dizzyEyes(canvas, a, b);
      case _Mood.effort:
        _effortEyes(canvas, a, b);
      case _Mood.focus:
        _focusEyes(canvas, a, b, look);
      case _Mood.startle:
        _wideEyes(canvas, a, b, look);
      case _Mood.wary:
        _waryEyes(canvas, a, b, look);
      case _Mood.walk:
        _eyes(canvas, a, b, false, look);
      case _Mood.land:
        _eyes(canvas, a, b, true, look);
      case _Mood.calm:
        _eyes(canvas, a, b, d.blink, look);
    }
  }

  static void _brows(Canvas canvas, Offset a, Offset? b, double slant) {
    void one(Offset c, double dir) {
      canvas.drawLine(
        c + Offset(-2.6, -3.8 - slant * dir),
        c + Offset(2.6, -3.8 + slant * dir),
        _brow,
      );
    }

    one(a, -1);
    if (b != null) {
      one(b, 1);
    }
  }

  static void _effortEyes(Canvas canvas, Offset a, Offset? b) {
    void one(Offset c) {
      canvas.drawLine(c + const Offset(-3.0, 0.2), c + const Offset(3.0, 0.8), _lid);
    }

    one(a);
    if (b != null) {
      one(b);
    }
    _brows(canvas, a, b, 0.9);
  }

  static void _focusEyes(Canvas canvas, Offset a, Offset? b, double look) {
    void one(Offset c) {
      canvas.drawCircle(c, 2.7, _eye);
      canvas.drawCircle(c + Offset(0.5 + look * 0.1, 0.55), 0.7, _eyeWhite);
    }

    one(a);
    if (b != null) {
      one(b);
    }
    _brows(canvas, a, b, -0.15);
  }

  static void _wideEyes(Canvas canvas, Offset a, Offset? b, double look) {
    void one(Offset c) {
      canvas.drawCircle(c, 3.7, _eyeWhite);
      canvas.drawCircle(c, 2.7, _eye);
      canvas.drawCircle(c + Offset(0.7 + look * 0.1, -1.15), 1.05, _eyeWhite);
    }

    one(a);
    if (b != null) {
      one(b);
    }
  }

  static void _waryEyes(Canvas canvas, Offset a, Offset? b, double look) {
    void one(Offset c) {
      canvas.drawCircle(c, 3.35, _eye);
      canvas.drawCircle(c + Offset(1.15 + look * 0.2, -0.35), 0.85, _eyeWhite);
    }

    one(a);
    if (b != null) {
      one(b);
    }
    _brows(canvas, a, b, 0.55);
  }

  static void _dizzyEyes(Canvas canvas, Offset a, Offset? b) {
    void one(Offset c) {
      final p = Path()
        ..moveTo(c.dx - 2.8, c.dy - 1.1)
        ..quadraticBezierTo(c.dx - 0.8, c.dy + 2.2, c.dx + 1.2, c.dy)
        ..quadraticBezierTo(c.dx + 2.6, c.dy - 1.4, c.dx + 0.4, c.dy - 0.2);
      canvas.drawPath(p, _lid);
    }

    one(a);
    if (b != null) {
      one(b);
    }
  }

  static void _eyes(Canvas canvas, Offset a, Offset? b, bool blink, double look) {
    void one(Offset c) {
      if (blink) {
        canvas.drawLine(c + const Offset(-3.2, 0.4), c + const Offset(3.2, 0.4), _lid);
        return;
      }
      canvas.drawCircle(c, 3.15, _eye);
      final shine = c + Offset(0.95 + look * 0.1, -1.05);
      canvas.drawCircle(shine, 1.15, _eyeWhite);
      canvas.drawCircle(c + const Offset(-0.85, 0.95), 0.45, _eyeWhite);
    }

    one(a);
    if (b != null) {
      one(b);
    }
  }

  static void _happyEyes(Canvas canvas, Offset a, [Offset? b]) {
    void one(Offset c) {
      final p = Path()
        ..moveTo(c.dx - 2.9, c.dy)
        ..quadraticBezierTo(c.dx, c.dy + 2.6, c.dx + 2.9, c.dy);
      canvas.drawPath(p, _lid);
    }

    one(a);
    if (b != null) {
      one(b);
    }
  }

  static void _hurtEyes(Canvas canvas, Offset a, [Offset? b]) {
    void one(Offset c) {
      canvas.drawLine(c + const Offset(-2.2, -1.6), c + const Offset(2.2, 1.6), _lid);
      canvas.drawLine(c + const Offset(-2.2, 1.6), c + const Offset(2.2, -1.6), _lid);
    }

    one(a);
    if (b != null) {
      one(b);
    }
  }

  static void _beakFront(Canvas canvas, {bool open = false}) {
    if (open) {
      canvas.drawOval(Rect.fromCenter(center: const Offset(0, 3.4), width: 5.6, height: 4.6), _beak);
      canvas.drawOval(Rect.fromCenter(center: const Offset(0, 3.7), width: 2.8, height: 2.3), _beakShade);
      return;
    }
    canvas.drawPath(_beakFrontPath, _beak);
    canvas.drawLine(const Offset(-1.4, 3.6), const Offset(1.4, 3.6), _beakLine);
    canvas.drawCircle(const Offset(0, 4.6), 0.9, _beakShade);
  }

  static void _wing(Canvas canvas, double dir, double flap) {
    canvas.save();
    canvas.translate(11.8 * dir, 3.6);
    canvas.rotate(dir * (0.32 + flap));
    final x = dir < 0 ? -10.0 : -2.0;
    canvas.drawOval(Rect.fromLTWH(x, -5.2, 13.5, 10), _wingSoft);
    canvas.drawOval(Rect.fromLTWH(x + (dir < 0 ? 2.2 : 1), -2.4, 9.5, 6), _shade);
    canvas.restore();
  }

  static void _walkFeetFront(Canvas canvas, double progress) {
    final w = _Walk.of(progress);
    void one(double x, {required bool swinging}) {
      final up = swinging && w.lift > 0.04;
      final inward = up ? -x.sign * (1.3 * w.lift) : x.sign * 0.35 * w.stanceLoad;
      _foot(
        canvas,
        Offset(x + inward, 13.8 - (up ? w.lift * 5.6 : 0)),
        tilt: up ? w.swingToe * 0.34 : w.stanceToe * 0.16,
        squash: up ? 0 : w.stanceLoad,
      );
    }

    if (w.leftSwing) {
      one(7.3, swinging: false);
      one(-7.3, swinging: true);
    } else {
      one(-7.3, swinging: false);
      one(7.3, swinging: true);
    }
  }

  static void _walkFeetSide(Canvas canvas, double progress) {
    final w = _Walk.of(progress);
    final plant = Offset(2.4 + w.stanceX * 7.2, 14.5);
    final swing = Offset(2.4 + w.swingX * 7.2, 14.5 - w.lift * 6.4);
    void draw(Offset p, {required bool swinging}) {
      final up = swinging && w.lift > 0.04;
      _footSide(
        canvas,
        p,
        tilt: up ? w.swingToe * 0.55 : w.stanceToe * 0.28,
        squash: up ? 0 : w.stanceLoad,
      );
    }

    if (plant.dx <= swing.dx) {
      draw(plant, swinging: false);
      draw(swing, swinging: true);
    } else {
      draw(swing, swinging: true);
      draw(plant, swinging: false);
    }
  }

  static void _footPair(Canvas canvas, double step, double amp) {
    _foot(canvas, Offset(-6.5, 13 + (step > 0 ? -amp * step.abs() : 0)));
    _foot(canvas, Offset(6.5, 13 + (step < 0 ? -amp * step.abs() : 0)));
  }

  static void _tuckedFeet(Canvas canvas) {
    _foot(canvas, const Offset(-5.5, 9));
    _foot(canvas, const Offset(5.5, 9));
  }

  static void _foot(Canvas canvas, Offset p, {double tilt = 0, double squash = 0}) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(tilt);
    canvas.scale(1 + squash * 0.22, 1 - squash * 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 5, height: 7),
        const Radius.circular(2),
      ),
      _footPaint,
    );
    canvas.drawLine(const Offset(-1.5, 3.1), const Offset(-4.4, 5.1), _toe);
    canvas.drawLine(const Offset(0.1, 3.4), const Offset(0.2, 5.4), _toe);
    canvas.drawLine(const Offset(1.5, 3.1), const Offset(4.2, 5.1), _toe);
    canvas.restore();
  }

  static void _footSide(Canvas canvas, Offset p, {double tilt = 0, double squash = 0}) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(tilt);
    canvas.scale(1 + squash * 0.2, 1 - squash * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0.8, 0.2), width: 6.4, height: 5.4),
        const Radius.circular(2.2),
      ),
      _footPaint,
    );
    canvas.drawLine(const Offset(2.0, 0.1), const Offset(7.1, 0.7), _toe);
    canvas.drawLine(const Offset(1.8, 1.5), const Offset(6.2, 2.8), _toe);
    canvas.drawLine(const Offset(1.2, 2.4), const Offset(4.6, 4.4), _toe);
    canvas.restore();
  }
}
