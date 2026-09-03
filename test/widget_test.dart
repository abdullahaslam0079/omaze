import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omaze/game/hop_game.dart';
import 'package:omaze/game/hop/domain/domain.dart';
import 'package:omaze/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('menu offers play', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(HopApp(game: HopGame()));
    await tester.pump();

    expect(find.text('HOP'), findsOneWidget);
    expect(find.byKey(const Key('play')), findsOneWidget);
  });

  testWidgets('play starts a run', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final game = HopGame();
    await tester.pumpWidget(HopApp(game: game));
    await tester.pump();

    await tester.tap(find.byKey(const Key('play')));
    await tester.pump();

    expect(game.phase, HopPhase.play);
    expect(find.text('HOP'), findsNothing);
    expect(game.score, 0);
    expect(game.px, HopGame.startLane.toDouble());
  });

  testWidgets('chick can weave across a wide field', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final game = HopGame();
    await tester.pumpWidget(HopApp(game: game));
    await tester.pump();
    game.start();

    expect(HopGame.lanes, greaterThan(5));
    expect(game.px, HopGame.startLane.toDouble());

    var hops = 0;
    while (game.px < HopGame.lanes - 1 && hops < 20) {
      game.hopT = 1;
      game.hop(1, 0);
      hops++;
    }
    expect(game.px, HopGame.lanes - 1);
    expect(hops, greaterThan(4));

    hops = 0;
    while (game.px > 0 && hops < 20) {
      game.hopT = 1;
      game.hop(-1, 0);
      hops++;
    }
    expect(game.px, 0);
    expect(hops, greaterThan(8));
  });
}
