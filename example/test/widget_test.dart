import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_nav_bar/liquid_glass_nav_bar.dart';
import 'package:liquid_glass_nav_bar_example/main.dart';

void main() {
  testWidgets('the example app switches tabs', (tester) async {
    await tester.pumpWidget(const LiquidGlassExampleApp());
    expect(find.byType(LiquidGlassNavBar), findsOneWidget);
    expect(find.text('4'), findsOneWidget); // unread messages badge

    // The feed posts use the same icon, so look only inside the bar.
    await tester.tap(find.descendant(
      of: find.byType(LiquidGlassNavBar),
      matching: find.byIcon(Icons.send_outlined),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Friend 0'), findsOneWidget);
    expect(find.text('4'), findsNothing); // opening Messages clears it
  });
}
