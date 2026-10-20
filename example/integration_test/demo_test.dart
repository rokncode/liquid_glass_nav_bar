// Runs on a device or simulator and walks through the bar's behaviors.
// It doubles as the script used to record the README GIFs:
//
//   flutter test integration_test -d <device>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_nav_bar/liquid_glass_nav_bar.dart';
import 'package:liquid_glass_nav_bar_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> idle(WidgetTester tester, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> slowDrag(
    WidgetTester tester,
    Offset from,
    Offset to, {
    int steps = 40,
    bool hold = false,
  }) async {
    final gesture = await tester.startGesture(from);
    for (var i = 1; i <= steps; i++) {
      await gesture.moveTo(Offset.lerp(from, to, i / steps)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    if (hold) await idle(tester, 500);
    await gesture.up();
  }

  testWidgets('demo walkthrough', (tester) async {
    await tester.pumpWidget(const LiquidGlassExampleApp());
    await idle(tester, 3000); // let the photos load

    final list = find.byType(CustomScrollView).first;

    // 1. Scroll down: the bar shrinks. Scroll up: it expands.
    await slowDrag(tester, tester.getCenter(list), tester.getCenter(list) - const Offset(0, 300));
    await idle(tester, 1200);
    await slowDrag(tester, tester.getCenter(list), tester.getCenter(list) + const Offset(0, 120));
    await idle(tester, 1200);

    // 2. Press on Home and drag the lens all the way to Profile, hold, release.
    // Aim at the icons themselves. With extendBody, the body's MediaQuery
    // padding already includes the bar, so it can't be used to find the bar.
    final home = tester.getCenter(find.byIcon(Icons.home_rounded));
    final reels = tester.getCenter(find.byIcon(Icons.smart_display_outlined));
    final search = tester.getCenter(find.byIcon(Icons.search_rounded));
    await slowDrag(tester, home, Offset(search.dx + (search.dx - reels.dx) * 0.5, home.dy), steps: 70, hold: true);
    await idle(tester, 1200);
    expect(find.text('Nav bar playground'), findsOneWidget); // landed on Profile

    // 3. Drag back to the middle and release between two tabs: it snaps.
    await slowDrag(tester, Offset(search.dx + (search.dx - reels.dx) * 0.5, home.dy), Offset(reels.dx + 20, home.dy), steps: 60);
    await idle(tester, 1200);
    expect(find.text('Reel #0'), findsOneWidget);

    // 4. Tap back to Home.
    await tester.tap(find.byIcon(Icons.home_outlined));
    await idle(tester, 1200);
    expect(find.text('Liquid Glass'), findsOneWidget);
    expect(find.byType(LiquidGlassNavBar), findsOneWidget);
  });
}
