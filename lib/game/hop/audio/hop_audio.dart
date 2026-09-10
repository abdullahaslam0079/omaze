import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:omaze/game/hop/domain/enums.dart';

/// Central SFX for Hop.
///
/// Preloads each cue into an [AudioPool] so hops reuse native players instead of
/// spawning a new one per tap (which made the game hitch).
class HopAudio {
  HopAudio._();
  static final HopAudio instance = HopAudio._();

  static const _sfx = [
    'hop.wav',
    'step.wav',
    'leap.wav',
    'pad.wav',
    'land.wav',
    'pad_land.wav',
    'bonk.wav',
    'collect.wav',
    'near.wav',
    'splash.wav',
    'flatten.wav',
    'combo.wav',
    'ui.wav',
    'start.wav',
  ];

  static const _busy = {'hop.wav', 'step.wav', 'land.wav', 'leap.wav', 'pad.wav'};

  final Map<String, AudioPool> _pools = {};
  bool _ready = false;
  bool _initStarted = false;
  bool muted = false;

  Future<void> init() async {
    if (_ready || _initStarted) return;
    _initStarted = true;

    try {
      try {
        await FlameAudio.bgm.stop();
      } catch (_) {}

      await FlameAudio.audioCache.loadAll(_sfx);

      await Future.wait(_sfx.map((file) async {
        _pools[file] = await FlameAudio.createPool(
          file,
          minPlayers: 1,
          maxPlayers: _busy.contains(file) ? 3 : 2,
        );
      }));
      _ready = true;
    } on MissingPluginException catch (e) {
      debugPrint(
        'HopAudio: native plugin missing ($e). '
        'Stop the app completely and run again (not hot restart).',
      );
      _ready = false;
      _initStarted = false;
    } catch (e) {
      debugPrint('HopAudio: init failed: $e');
      _ready = false;
      _initStarted = false;
    }
  }

  void setMuted(bool value) {
    muted = value;
  }

  void ui() => _sfxPlay('ui.wav', 0.55);

  void startRun() => _sfxPlay('start.wav', 0.7);

  void move(HopMove kind) {
    switch (kind) {
      case HopMove.step:
        _sfxPlay('step.wav', 0.45);
      case HopMove.hop:
        _sfxPlay('hop.wav', 0.62);
      case HopMove.leap:
        _sfxPlay('leap.wav', 0.72);
    }
  }

  /// Takeoff from a water pad / lily.
  void pad() => _sfxPlay('pad.wav', 0.65);

  void land({required bool onWater}) {
    if (onWater) {
      _sfxPlay('pad_land.wav', 0.55);
    } else {
      _sfxPlay('land.wav', 0.5);
    }
  }

  void bonk() => _sfxPlay('bonk.wav', 0.7);

  void collect() => _sfxPlay('collect.wav', 0.75);

  void nearMiss() => _sfxPlay('near.wav', 0.55);

  void combo() => _sfxPlay('combo.wav', 0.6);

  void dieFlattened() => _sfxPlay('flatten.wav', 0.85);

  void dieSplash() => _sfxPlay('splash.wav', 0.8);

  void _sfxPlay(String file, double volume) {
    if (!_ready || muted) return;
    final pool = _pools[file];
    if (pool == null) return;
    // Fire-and-forget; pool recycles players when the clip ends.
    pool.start(volume: volume).then((_) {}, onError: (e) {
      if (e is MissingPluginException) _ready = false;
    });
  }
}
