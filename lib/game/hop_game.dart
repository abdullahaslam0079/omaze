import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/services.dart';

import 'package:omaze/game/chick.dart';
import 'package:omaze/game/hop/components/components.dart';
import 'package:omaze/game/hop/domain/domain.dart';
import 'package:omaze/game/hop/render/render.dart';
import 'package:omaze/game/score_store.dart';

/// The main Flame game for Hop.
///
/// Orchestrates domain logic (world generation, collision, scoring)
/// and delegates rendering to per-object renderers.
class HopGame extends FlameGame {
  // ── Overlay keys ──
  static const menuOverlay = 'menu';
  static const overOverlay = 'over';

  // ── Grid constants ──
  static const lanes = WorldGenerator.lanes;
  static const visibleLanes = 5.0;
  static const startLane = WorldGenerator.startLane;

  // ── Hop physics constants ──
  static const _stepRate = 4.2;
  static const _hopRate = 6.8;
  static const _leapRate = 3.35;
  static const _hopHeight = 26.0;
  static const _leapHeight = 62.0;

  // ── Services ──
  final _store = ScoreStore();
  final _rng = math.Random();
  late final WorldGenerator worldGen = WorldGenerator(rng: _rng);

  // ── Player state ──
  HopPhase phase = HopPhase.menu;
  int score = 0;
  int best = 0;
  int loot = 0;
  double px = startLane.toDouble();
  int pz = 0;
  int maxZ = 0;
  double hopT = 1;
  double hopPeak = 26;
  double hopRate = 6.8;
  double _landImpact = 0;
  HopMove hopMove = HopMove.hop;
  double fromX = startLane.toDouble();
  int fromZ = 0;
  double cam = 0;
  double camX = startLane + 0.5;
  double shake = 0;
  double splash = 0;
  double squash = 0;
  double scorePop = 0;
  double time = 0;
  double overWait = 0;
  final chick = ChickAnim();
  bool flattened = false;
  bool overShown = false;
  int face = 0;
  int combo = 0;
  int bestCombo = 0;
  double comboPop = 0;
  double hint = 1;
  double _nearCool = 0;
  int? _queuedDx;
  int? _queuedDz;
  HopMove _queuedMove = HopMove.hop;
  Mover? _rideLog;
  double _rideOffset = 0.5;

  // ── Particles ──
  final fx = <FxParticle>[];

  // ── Computed helpers ──
  double get tile => size.x <= 0 ? 78 : size.x / visibleLanes;
  double get ground => size.y * 0.78;
  double get horizon => size.y * 0.30;
  double get _minCamX => visibleLanes * 0.5 - 0.2;
  double get _maxCamX => lanes - visibleLanes * 0.5 + 0.2;

  @override
  Color backgroundColor() => const Color(0xFF1A1440);

  // ── Lifecycle ──

  @override
  Future<void> onLoad() async {
    add(PlayfieldInput());
    _store.load().then((value) => best = value);
    _resetWorld();
  }

  void start() {
    resumeEngine();
    overlays.remove(menuOverlay);
    overlays.remove(overOverlay);
    phase = HopPhase.play;
    score = 0;
    loot = 0;
    px = startLane.toDouble();
    pz = 0;
    maxZ = 0;
    hopT = 1;
    hopPeak = _hopHeight;
    hopRate = _hopRate;
    _landImpact = 0;
    hopMove = HopMove.hop;
    fromX = startLane.toDouble();
    fromZ = 0;
    cam = 0;
    camX = startLane + 0.5;
    shake = 0;
    splash = 0;
    squash = 0;
    scorePop = 0;
    combo = 0;
    bestCombo = 0;
    comboPop = 0;
    hint = 1;
    _nearCool = 0;
    _queuedDx = null;
    _queuedDz = null;
    _queuedMove = HopMove.hop;
    flattened = false;
    overShown = false;
    overWait = 0;
    face = 0;
    chick.reset();
    fx.clear();
    _clearRide();
    _resetWorld();
  }

  void showMenu() {
    resumeEngine();
    phase = HopPhase.menu;
    overlays.remove(overOverlay);
    overlays.add(menuOverlay);
    px = startLane.toDouble();
    fromX = startLane.toDouble();
    pz = 0;
    camX = startLane + 0.5;
    hopT = 1;
    hopPeak = _hopHeight;
    hopRate = _hopRate;
    _landImpact = 0;
    hopMove = HopMove.hop;
    splash = 0;
    flattened = false;
    overShown = false;
    face = 0;
    chick.reset();
    combo = 0;
    comboPop = 0;
    _queuedDx = null;
    _queuedDz = null;
    _queuedMove = HopMove.hop;
    fx.clear();
    _clearRide();
    _resetWorld();
  }

  // ── Input ──

  void hop(int dx, int dz, {HopMove? move}) {
    if (phase != HopPhase.play) return;
    var kind = move ?? HopMove.hop;
    if (dx != 0 || dz < 0) {
      kind = HopMove.step;
    } else if (dz > 0 && kind != HopMove.leap) {
      kind = HopMove.hop;
    }
    if (hopT < 1) {
      if (hopT > 0.52) {
        _queuedDx = dx;
        _queuedDz = dz;
        _queuedMove = kind;
      }
      return;
    }
    _commitHop(dx, dz, kind);
  }

  // ── World access ──

  HopRow _row(int z) => worldGen.getRow(z, pz);

  void _resetWorld() {
    worldGen.reset();
    worldGen.ensureAhead(pz);
  }

  // ── Hop logic ──

  void _commitHop(int dx, int dz, HopMove kind) {
    if (kind == HopMove.leap && dz > 0) {
      dz = 2;
    } else if (dz > 0) {
      dz = 1;
      kind = HopMove.hop;
    } else if (dz < 0) {
      dz = -1;
      kind = HopMove.step;
    }
    if (dx != 0) kind = HopMove.step;

    final nx = (px + dx).clamp(0.0, lanes - 1.0);
    final nz = pz + dz;
    final lane = nx.round().clamp(0, lanes - 1);
    if (nz < 0 ||
        (dx != 0 && nx == px) ||
        CollisionRules.treeAt(nz, lane, worldGen, pz) ||
        (kind == HopMove.leap && CollisionRules.treeAt(pz + 1, lane, worldGen, pz))) {
      _bonk(dx, dz);
      return;
    }
    final dest = _row(nz);
    fromX = px;
    fromZ = pz;
    pz = nz;
    if (dest.kind == RowKind.water) {
      _boardFloater(dest, nx + dest.dir * dest.speed * 0.12);
    } else {
      _clearRide();
      px = lane.toDouble();
    }
    hopT = 0;
    hopMove = kind;
    switch (kind) {
      case HopMove.step:
        hopPeak = 0;
        hopRate = _stepRate;
      case HopMove.hop:
        hopPeak = _hopHeight;
        hopRate = _hopRate;
      case HopMove.leap:
        hopPeak = _leapHeight;
        hopRate = _leapRate;
    }
    face = dx;
    hint = math.max(0, hint - 0.28);
    if (dz > 0) {
      combo += dz;
      if (combo > bestCombo) bestCombo = combo;
      if (combo >= 3) comboPop = 1;
    } else {
      combo = 0;
    }
    HapticFeedback.lightImpact();
    if (kind == HopMove.leap) HapticFeedback.mediumImpact();
    if (pz > maxZ) {
      maxZ = pz;
      score = ScoringRules.computeScore(maxZ, loot);
      scorePop = 1;
    }
    worldGen.ensureAhead(pz);
  }

  void _bonk(int dx, int dz) {
    if (phase != HopPhase.play || flattened) return;
    face = dx;
    chick.playBump();
    shake = math.max(shake, 0.42);
    HapticFeedback.mediumImpact();
    _burst(
      px + 0.5 + dx * 0.28,
      pz + 0.28 + (dz > 0 ? 0.22 : dz < 0 ? -0.12 : 0),
      const Color(0xCCF4D27A),
      6,
    );
  }

  // ── Update ──

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;

    // Hop progress
    final wasHopping = hopT < 1;
    hopT = math.min(1, hopT + dt * hopRate);
    if (wasHopping && hopT < 1 && phase == HopPhase.play && hopMove == HopMove.leap) {
      final t = hopT * (2 - hopT);
      _burst(fromX + (px - fromX) * t + 0.5, fromZ + (pz - fromZ) * t + 0.2, const Color(0xCCF4C542), 3);
    } else if (wasHopping && hopT < 1 && phase == HopPhase.play && hopMove != HopMove.step && _rng.nextDouble() < 0.55) {
      final t = hopT * (2 - hopT);
      _burst(fromX + (px - fromX) * t + 0.5, fromZ + (pz - fromZ) * t + 0.2, const Color(0xAAF4D27A), 2);
    }
    if (wasHopping && hopT >= 1 && phase == HopPhase.play) {
      if (hopMove != HopMove.step) {
        _landImpact = _landingImpact();
        squash = _landImpact;
        _landDust();
        HapticFeedback.selectionClick();
      }
      _collect();
      final qx = _queuedDx;
      final qz = _queuedDz;
      _queuedDx = null;
      _queuedDz = null;
      if (qx != null && qz != null) _commitHop(qx, qz, _queuedMove);
    }

    // Decay timers — squash recovers with a soft spring overshoot.
    shake = math.max(0, shake - dt * 3.6);
    splash = math.max(0, splash - dt);
    if (squash > 0) {
      squash -= dt * 4.4;
      if (squash < 0 && _landImpact > 0.55) {
        squash = -math.min(0.14, _landImpact * 0.12);
        _landImpact *= 0.35;
      } else if (squash < 0) {
        squash = 0;
        _landImpact = 0;
      }
    } else if (squash < 0) {
      squash += dt * 5.2;
      if (squash >= 0) {
        squash = 0;
        _landImpact = 0;
      }
    }
    scorePop = math.max(0, scorePop - dt * 3.2);
    comboPop = math.max(0, comboPop - dt * 2.4);
    hint = phase == HopPhase.play ? math.max(0, hint - dt * 0.12) : hint;
    _nearCool = math.max(0, _nearCool - dt);
    chick.update(dt, _chickPose(), _rng);

    // Camera — soft follow with slight lookahead while in air.
    final airLead = hopT < 1 && hopMove != HopMove.step ? (1 - hopT) * hopPeak * 0.18 : 0.0;
    final target = pz * tile + 10 + airLead;
    final camEase = hopT < 1 ? 5.2 : 4.4;
    cam += (target - cam) * math.min(1, dt * camEase);
    if (!_ridingCurrent) {
      final targetX = (_liveX + 0.5).clamp(_minCamX, _maxCamX);
      camX += (targetX - camX) * math.min(1, dt * 5.6);
    }

    // Movers
    for (final row in worldGen.rows.values) {
      if (row.speed == 0) continue;
      for (final mover in row.movers) {
        mover.x += row.dir * row.speed * dt;
        final wrap = mover.train ? 22.0 : 2.5;
        if (row.dir > 0 && mover.x > lanes + wrap) mover.x = -wrap - (mover.train ? 6 : 0);
        if (row.dir < 0 && mover.x < -wrap) mover.x = lanes + wrap + (mover.train ? 6 : 0);
      }
    }
    _trackRide();

    // Coins
    for (final coin in worldGen.coins) {
      if (coin.taken) coin.pop = math.min(1, coin.pop + dt * 4);
    }

    // Particles
    for (final p in fx) {
      p.x += p.vx * dt;
      p.vz -= p.gravity * dt;
      p.z += p.vz * dt;
      p.life -= dt;
    }
    fx.removeWhere((p) => p.life <= 0);

    // Hazards
    if (phase == HopPhase.play && (hopT >= 1 || hopMove == HopMove.step)) {
      if (hopT >= 1) _rideLogs(dt);
      _currentWarn();
      _nearMiss();
      _checkDeath();
    }

    // Game over delay
    if (phase == HopPhase.dead && !overShown) {
      overWait -= dt;
      if (overWait <= 0) {
        overShown = true;
        overlays.add(overOverlay);
      }
    }
  }

  // ── Render ──

  @override
  void render(Canvas canvas) {
    final ctx = HopRenderContext(
      size: size.toSize(),
      tile: tile,
      ground: ground,
      horizon: horizon,
      cam: cam,
      camX: camX,
      time: time,
      shake: shake,
      rows: worldGen.rows,
    );

    SkyRenderer.draw(canvas, ctx);

    // Soft-fade only the last half-tile under the mountains; playfield stays crisp.
    final playBounds = Rect.fromLTRB(0, horizon - 6, size.x, size.y + 2);
    canvas.saveLayer(playBounds, Paint());
    canvas.clipRect(playBounds);
    final keys = worldGen.rows.keys.toList()..sort();
    for (final z in keys) {
      GroundRenderer.drawRow(canvas, worldGen.rows[z]!, ctx);
    }
    CoinRenderer.drawAll(canvas, worldGen.coins, ctx);
    FxRenderer.drawAll(canvas, fx, ctx);
    PlayerRenderer.draw(
      canvas,
      PlayerRenderData(
        phase: phase,
        px: px,
        pz: pz,
        fromX: fromX,
        fromZ: fromZ,
        hopT: hopT,
        hopMove: hopMove,
        hopPeak: hopPeak,
        hopLift: _hopLift(),
        along: _along(),
        squash: squash,
        splash: splash,
        flattened: flattened,
        face: face,
        chick: chick,
        ridingCurrent: _ridingCurrent,
        rideLog: _rideLog,
        waryDir: _waryDir(),
      ),
      ctx,
      _row,
    );
    canvas.drawRect(
      playBounds,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = SkyRenderer.playfieldFade(ctx),
    );
    canvas.restore();

    SkyRenderer.drawHorizonMist(canvas, ctx);
    SkyRenderer.drawFireflies(canvas, ctx);
    if (phase == HopPhase.play) {
      HudRenderer.draw(
        canvas,
        ctx,
        score: score,
        loot: loot,
        combo: combo,
        maxZ: maxZ,
        scorePop: scorePop,
        comboPop: comboPop,
        hint: hint,
      );
    }
    super.render(canvas);
  }

  // ── Ride / water helpers ──

  bool get _ridingCurrent => hopT >= 1 && phase == HopPhase.play && _row(pz).kind == RowKind.water;

  void _clearRide() {
    _rideLog = null;
    _rideOffset = 0.5;
  }

  void _boardFloater(HopRow row, double x) {
    final log = CollisionRules.nearestFloater(x, row);
    if (log == null) {
      _clearRide();
      px = x;
      return;
    }
    _rideLog = log;
    _rideOffset = (x + 0.5 - log.x).clamp(0.2, log.w - 0.2);
    px = log.x + _rideOffset - 0.5;
  }

  void _trackRide() {
    final log = _rideLog;
    if (log == null || _row(pz).kind != RowKind.water) return;
    final next = log.x + _rideOffset - 0.5;
    if ((next - px).abs() > 1.4) {
      _clearRide();
      return;
    }
    px = next;
  }

  void _rideLogs(double dt) {
    final row = _row(pz);
    if (row.kind != RowKind.water) {
      px = px.roundToDouble().clamp(0, lanes - 1);
      _clearRide();
      return;
    }
    if (_rideLog == null || !row.movers.contains(_rideLog)) {
      _boardFloater(row, px);
    }
    _trackRide();
    if (_rideLog == null) px += row.dir * row.speed * dt;
  }

  // ── Hazard helpers ──

  void _currentWarn() {
    if (!_ridingCurrent || _nearCool > 0) return;
    if (size.x <= 0) return;
    final sx = (_liveX + 0.5 - camX) * tile + size.x * 0.5;
    if (sx < tile * 0.72 || sx > size.x - tile * 0.72) {
      _nearCool = 0.55;
      chick.playStartle();
      _burst(_liveX + 0.5, pz + 0.2, const Color(0x88A8F0FF), 4);
    }
  }

  bool _floatedOffScreen() {
    if (size.x <= 0) return false;
    final sx = (_liveX + 0.5 - camX) * tile + size.x * 0.5;
    return sx < -tile * 0.4 || sx > size.x + tile * 0.4;
  }

  void _collect() {
    final collected = ScoringRules.collect(worldGen.coins, pz, px);
    for (final _ in collected) {
      loot += 1;
      score = ScoringRules.computeScore(maxZ, loot);
      scorePop = 1;
      HapticFeedback.mediumImpact();
      chick.playCollect();
      _burst(px + 0.5, pz + 0.3, const Color(0xFFE8C36A), 10);
    }
  }

  void _nearMiss() {
    if (_nearCool > 0) return;
    final row = _row(_liveZ.round());
    final cx = _liveX + 0.5;
    if (CollisionRules.nearMiss(row, cx)) {
      _nearCool = 0.4;
      HapticFeedback.selectionClick();
      chick.playStartle();
      _burst(_liveX + 0.5, _liveZ + 0.2, const Color(0x88F4C542), 4);
    }
  }

  void _checkDeath() {
    final row = _row(hopMove == HopMove.step ? _liveZ.round() : pz);
    final cx = _liveX + 0.5;
    final cause = CollisionRules.checkDeath(
      row: row,
      cx: cx,
      px: px,
      lanes: lanes,
      floatedOffScreen: _floatedOffScreen(),
    );
    switch (cause) {
      case DeathCause.none:
        break;
      case DeathCause.flattened:
        flattened = true;
        final mover = row.movers.firstWhere((c) => cx > c.x + 0.08 && cx < c.x + c.w - 0.08);
        _burst(px + 0.5, pz + 0.25, mover.color, 10);
        _die();
      case DeathCause.drowned:
        splash = 0.75;
        flattened = false;
        _burst(px + 0.5, pz + 0.25, const Color(0xAAE8FFFF), 14);
        _die();
    }
  }

  void _die() {
    if (phase != HopPhase.play) return;
    phase = HopPhase.dead;
    shake = 0.7;
    overWait = 0.48;
    _queuedDx = null;
    _queuedDz = null;
    _queuedMove = HopMove.hop;
    _clearRide();
    overShown = false;
    HapticFeedback.heavyImpact();
    if (score > best) {
      best = score;
      _store.save(best);
    }
  }

  // ── Particles ──

  void _landDust() {
    final row = _row(pz);
    if (row.kind == RowKind.water) {
      _burst(px + 0.5, pz + 0.2, const Color(0x88A8F0FF), 8);
      for (var i = 0; i < 5; i++) {
        fx.add(FxParticle(
          px + 0.5, pz + 0.18,
          row.dir * (0.6 + _rng.nextDouble() * 1.4),
          (_rng.nextDouble() - 0.35) * 1.1,
          0.32 + _rng.nextDouble() * 0.16,
          const Color(0xAAD8F8FF),
          2.0 + _rng.nextDouble() * 2.2,
        ));
      }
      return;
    }
    final n = hopMove == HopMove.leap ? 14 : 9;
    for (var i = 0; i < n; i++) {
      final grass = i.isEven;
      fx.add(FxParticle(
        px + 0.5 + (_rng.nextDouble() - 0.5) * 0.35,
        pz + 0.2,
        (_rng.nextDouble() - 0.5) * 2.8,
        0.6 + _rng.nextDouble() * 1.8,
        0.34 + _rng.nextDouble() * 0.22,
        grass ? const Color(0xCC4CA050) : const Color(0xAA8A6A38),
        1.6 + _rng.nextDouble() * 2.4,
        gravity: 4.8,
      ));
    }
    _burst(px + 0.5, pz + 0.18, const Color(0x55FFFFFF), hopMove == HopMove.leap ? 6 : 3);
  }

  void _burst(double x, double z, Color color, int n) {
    for (var i = 0; i < n; i++) {
      fx.add(FxParticle(
        x, z,
        (_rng.nextDouble() - 0.5) * 2.4,
        (_rng.nextDouble() - 0.2) * 1.6,
        0.28 + _rng.nextDouble() * 0.18,
        color,
        2.2 + _rng.nextDouble() * 2.4,
      ));
    }
  }

  // ── Animation helpers ──

  int _waryDir() {
    if (phase != HopPhase.play || hopT < 1 || flattened || chick.bumpT > 0) return 0;
    final lane = px.round().clamp(0, lanes - 1);
    if (CollisionRules.treeAt(pz + 1, lane, worldGen, pz)) return 2;
    if (pz > 0 && CollisionRules.treeAt(pz - 1, lane, worldGen, pz)) return 3;
    if (lane > 0 && CollisionRules.treeAt(pz, lane - 1, worldGen, pz)) return -1;
    if (lane < lanes - 1 && CollisionRules.treeAt(pz, lane + 1, worldGen, pz)) return 1;
    return 0;
  }

  ChickPose _chickPose() {
    if (flattened || (phase == HopPhase.dead && splash <= 0)) return ChickPose.hurt;
    if (chick.collectT > 0) return ChickPose.collect;
    if (hopT < 1) {
      if (hopMove == HopMove.step) return ChickPose.walk;
      return _hopFallSpeed() <= 0 ? ChickPose.jump : ChickPose.fall;
    }
    if (squash > 0.18) return ChickPose.land;
    return ChickPose.idle;
  }

  double _along() {
    if (hopT >= 1) return 1;
    final t = hopT.clamp(0.0, 1.0);
    if (hopMove == HopMove.step) {
      // Ease in-out with soft settle so side-steps feel planted.
      return t * t * (3 - 2 * t);
    }
    // Forward hops: slow takeoff, quick mid travel, soft land.
    final shaped = switch (hopMove) {
      HopMove.leap => ((t - 0.06) / 0.88).clamp(0.0, 1.0),
      HopMove.hop => ((t - 0.04) / 0.90).clamp(0.0, 1.0),
      HopMove.step => t,
    };
    return shaped * shaped * (3 - 2 * shaped);
  }

  double get _liveX => fromX + (px - fromX) * _along();
  double get _liveZ => fromZ + (pz - fromZ) * _along();

  double _flightProgress() {
    if (hopMove == HopMove.step) return 0;
    return hopT.clamp(0.0, 1.0);
  }

  double _hopLiftAt(double t) {
    if (hopMove == HopMove.step || hopPeak <= 0) return 0;
    final u = t.clamp(0.0, 1.0);
    // Asymmetric arc: quick rise, floaty hang, heavier fall.
    final rise = hopMove == HopMove.leap ? 0.38 : 0.42;
    double travel;
    if (u <= rise) {
      final p = u / rise;
      travel = 0.5 * (1 - math.cos(math.pi * p));
    } else {
      final p = (u - rise) / (1 - rise);
      // Ease-in fall for weight.
      travel = 0.5 + 0.5 * (1 - math.pow(1 - p, 1.65));
      if (travel > 1) travel = 1;
    }
    final hang = hopMove == HopMove.leap
        ? 0.32 * math.sin(math.pi * travel)
        : 0.18 * math.sin(math.pi * travel);
    final arc = 4 * travel * (1 - travel);
    return hopPeak * (arc + hang * arc).clamp(0.0, 1.35);
  }

  double _hopLift() => _hopLiftAt(_flightProgress());

  double _hopFallSpeed() {
    if (hopMove == HopMove.step || hopPeak <= 0 || hopT >= 1) return 0;
    const sample = 0.02;
    final now = _flightProgress();
    final prev = math.max(0.0, now - sample);
    return (_hopLiftAt(prev) - _hopLiftAt(now)) / sample;
  }

  double _landingImpact() {
    if (hopMove == HopMove.step) return 0;
    final drop = (_hopFallSpeed() / math.max(1.0, hopPeak)).clamp(0.0, 1.45);
    final base = hopMove == HopMove.leap ? 0.82 : 0.64;
    return (base + drop * 0.48).clamp(0.0, 1.0);
  }
}
