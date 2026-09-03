import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'package:omaze/game/hop/domain/domain.dart';
import 'package:omaze/game/hop_game.dart';

/// Handles tap and drag input, translating gestures into hop commands.
class PlayfieldInput extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameReference<HopGame> {
  Vector2? _start;
  bool _swiped = false;

  @override
  Future<void> onLoad() async {
    size = game.size;
    position = Vector2.zero();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_swiped) {
      _swiped = false;
      return;
    }
    if (game.phase != HopPhase.play) return;
    final x = event.canvasPosition.x;
    final w = game.size.x;
    if (x < w * 0.22) {
      game.hop(-1, 0, move: HopMove.step);
    } else if (x > w * 0.78) {
      game.hop(1, 0, move: HopMove.step);
    } else {
      game.hop(0, 1, move: HopMove.hop);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _start = event.canvasPosition;
    _swiped = false;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _start = null;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _start = null;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final start = _start;
    if (start == null || game.phase != HopPhase.play) return;
    final delta = event.canvasEndPosition - start;
    if (delta.length < 22) return;
    _start = null;
    _swiped = true;
    if (delta.y.abs() > delta.x.abs()) {
      if (delta.y < 0) {
        game.hop(0, 1, move: delta.length > 96 ? HopMove.leap : HopMove.hop);
      } else {
        game.hop(0, -1, move: HopMove.step);
      }
    } else {
      game.hop(delta.x < 0 ? -1 : 1, 0, move: HopMove.step);
    }
  }
}
