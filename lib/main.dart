import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:omaze/game/hop_game.dart';
import 'package:omaze/game/overlays.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const HopApp());
}

class HopApp extends StatelessWidget {
  const HopApp({super.key, this.game});

  final HopGame? game;

  @override
  Widget build(BuildContext context) {
    final hop = game ?? HopGame();
    return MaterialApp(
      title: 'Hop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFF1A1440),
      ),
      home: Scaffold(
        body: GameWidget<HopGame>(
          game: hop,
          backgroundBuilder: (context) => const ColoredBox(color: Color(0xFF1A1440)),
          overlayBuilderMap: {
            HopGame.menuOverlay: (context, game) => MenuOverlay(game: game),
            HopGame.overOverlay: (context, game) => OverOverlay(game: game),
          },
          initialActiveOverlays: const [HopGame.menuOverlay],
        ),
      ),
    );
  }
}
