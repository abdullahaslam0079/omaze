import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omaze/game/hop/render/tree_renderer.dart';

/// Golden preview of the static hero tree for visual review.
void main() {
  testWidgets('hero tree preview golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColoredBox(
            color: const Color(0xFF1A1440),
            child: CustomPaint(
              painter: _HeroPreviewPainter(),
              size: const Size(360, 320),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CustomPaint).last,
      matchesGoldenFile('goldens/hero_tree_preview.png'),
    );
  });
}

class _HeroPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        const [Color(0xFF1A1440), Color(0xFF142818)],
      );
    canvas.drawRect(Offset.zero & size, bg);

    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.14),
      28,
      Paint()..color = const Color(0x55F0D8A0),
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.14),
      16,
      Paint()..color = const Color(0xFFF5E6B8),
    );

    TreeRenderer.drawHeroAt(
      canvas,
      Offset(size.width * 0.5, size.height * 0.78),
      scale: 2.35,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
