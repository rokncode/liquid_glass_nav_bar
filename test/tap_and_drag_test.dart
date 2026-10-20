import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('tap', () {
    testWidgets('selects the tab and settles the indicator on it',
        (tester) async {
      final taps = <int>[];
      final changes = <int>[];
      await tester.pumpWidget(Harness(onTap: taps.add, onTabChanged: changes.add));

      await tester.tap(find.byIcon(Icons.search_outlined));
      await tester.pumpAndSettle();

      expect(taps, [3]);
      expect(changes, [3]);
      expect(indicatorPosition(tester), 3.0);
      // The selected tab switches to its active icon.
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('re-tapping the selected tab fires onTap only', (tester) async {
      final taps = <int>[];
      final changes = <int>[];
      await tester.pumpWidget(Harness(onTap: taps.add, onTabChanged: changes.add));

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      expect(taps, [0]);
      expect(changes, isEmpty);
    });

    testWidgets('springs back when the parent keeps the old index',
        (tester) async {
      await tester.pumpWidget(const Harness(followTaps: false));

      await tester.tap(find.byIcon(Icons.search_outlined));
      await tester.pumpAndSettle();

      expect(indicatorPosition(tester), 0.0);
    });

    testWidgets('animates when currentIndex changes from outside',
        (tester) async {
      final key = GlobalKey<HarnessState>();
      await tester.pumpWidget(Harness(key: key));

      key.currentState!.setIndex(2);
      await tester.pump(); // rebuild; the spring starts here
      await tester.pump(); // the ticker's first frame
      await tester.pump(const Duration(milliseconds: 50));
      final mid = indicatorPosition(tester);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(2));

      await tester.pumpAndSettle();
      expect(indicatorPosition(tester), 2.0);
    });

    testWidgets('the spring never overshoots past the neighbor tab',
        (tester) async {
      await tester.pumpWidget(const Harness());

      await tester.tap(find.byKey(avatarKey));
      var maxSeen = 0.0;
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        final p = indicatorPosition(tester);
        if (p > maxSeen) maxSeen = p;
      }
      await tester.pumpAndSettle();

      expect(indicatorPosition(tester), 4.0);
      // It may bounce a little, but stays well short of the next slot and
      // never leaves the bar.
      expect(maxSeen, lessThanOrEqualTo(4.3));
    });
  });

  group('drag', () {
    testWidgets('dragging across tabs selects the one under the finger',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(Harness(onTap: taps.add));

      await dragAcross(tester, slotCenter(tester, 0), slotCenter(tester, 3));
      await tester.pumpAndSettle();

      expect(taps, [3]);
      expect(indicatorPosition(tester), 3.0);
    });

    testWidgets('the lens follows the finger between tabs', (tester) async {
      await tester.pumpWidget(const Harness());

      final gesture = await dragAcross(
        tester,
        slotCenter(tester, 0),
        slotCenter(tester, 1.5),
        release: false,
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(indicatorPosition(tester), closeTo(1.5, 0.02));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the lens grows past the bar while pressed and relaxes after',
        (tester) async {
      await tester.pumpWidget(const Harness());
      final bar = barRect(tester);
      final rest = indicatorOf(tester).indicatorRect(bar.size);
      expect(rest.height, lessThan(bar.height));

      final gesture = await dragAcross(
        tester,
        slotCenter(tester, 0),
        slotCenter(tester, 1),
        release: false,
      );
      await tester.pump(const Duration(milliseconds: 400));

      final painter = indicatorOf(tester);
      expect(painter.press(), closeTo(1, 0.001));
      final lens = painter.indicatorRect(bar.size);
      expect(lens.height, greaterThan(bar.height));
      expect(lens.width, greaterThan(rest.width * 1.1));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(indicatorOf(tester).press(), 0);
      final settled = indicatorOf(tester).indicatorRect(bar.size);
      final expected = rest.shift(Offset(slotWidth(tester), 0));
      expect(settled.left, closeTo(expected.left, 1e-6));
      expect(settled.size.width, closeTo(expected.width, 1e-6));
      expect(settled.size.height, closeTo(expected.height, 1e-6));
    });

    testWidgets('fast drags stretch the lens sideways', (tester) async {
      await tester.pumpWidget(const Harness());
      final bar = barRect(tester);

      final gesture = await tester.startGesture(slotCenter(tester, 0));
      var t = Duration.zero;
      Future<void> move(double dx) async {
        t += const Duration(milliseconds: 16);
        await gesture.moveBy(Offset(dx, 0), timeStamp: t);
        await tester.pump(const Duration(milliseconds: 16));
      }

      await move(30); // past the touch slop
      await move(40);
      await move(40);
      expect(indicatorOf(tester).stretch(), greaterThan(0.3));

      // Holding still lets the stretch fade out.
      await tester.pump(const Duration(milliseconds: 400));
      expect(indicatorOf(tester).stretch(), 0);
      expect(
        indicatorOf(tester).indicatorRect(bar.size).height,
        greaterThan(bar.height),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('releasing between tabs snaps to the nearest one',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(Harness(onTap: taps.add));

      await dragAcross(tester, slotCenter(tester, 0), slotCenter(tester, 1.4));
      await tester.pumpAndSettle();
      expect(taps, [1]);
      expect(indicatorPosition(tester), 1.0);

      await dragAcross(tester, slotCenter(tester, 1), slotCenter(tester, 2.6));
      await tester.pumpAndSettle();
      expect(taps, [1, 3]);
      expect(indicatorPosition(tester), 3.0);
    });

    testWidgets('dragging past the last tab rubber-bands', (tester) async {
      await tester.pumpWidget(const Harness(initialIndex: 3));

      final gesture = await dragAcross(
        tester,
        slotCenter(tester, 3),
        slotCenter(tester, 4) + const Offset(300, 0),
        release: false,
      );
      await tester.pump(const Duration(milliseconds: 200));
      final p = indicatorPosition(tester);
      expect(p, greaterThan(4));
      expect(p, lessThanOrEqualTo(4.3));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(indicatorPosition(tester), 4.0);
    });

    testWidgets('clicks once for each new tab the finger crosses',
        (tester) async {
      final haptics = recordHaptics(tester);
      await tester.pumpWidget(const Harness());

      await dragAcross(tester, slotCenter(tester, 0), slotCenter(tester, 3));
      await tester.pumpAndSettle();

      expect(haptics, List.filled(3, 'HapticFeedbackType.selectionClick'));
    });

    testWidgets('no haptics when they are turned off', (tester) async {
      final haptics = recordHaptics(tester);
      await tester.pumpWidget(const Harness(enableHaptics: false));

      await dragAcross(tester, slotCenter(tester, 0), slotCenter(tester, 3));
      await tester.pumpAndSettle();

      expect(haptics, isEmpty);
    });

    testWidgets('drags do nothing when drag-to-switch is off, taps still work',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        Harness(enableDragToSwitch: false, onTap: taps.add),
      );

      await dragAcross(tester, slotCenter(tester, 0), slotCenter(tester, 3));
      await tester.pumpAndSettle();
      expect(taps, isEmpty);
      expect(indicatorPosition(tester), 0.0);

      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pumpAndSettle();
      expect(taps, [2]);
    });
  });

  group('RTL', () {
    testWidgets('the first item sits on the right', (tester) async {
      await tester.pumpWidget(const Harness(textDirection: TextDirection.rtl));

      final home = tester.getCenter(find.byIcon(Icons.home));
      final search = tester.getCenter(find.byIcon(Icons.search_outlined));
      expect(home.dx, greaterThan(search.dx));
      expect(home.dx, closeTo(slotCenter(tester, 4).dx, 0.5));
    });

    testWidgets('tapping the leftmost slot selects the last item',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        Harness(textDirection: TextDirection.rtl, onTap: taps.add),
      );

      await tester.tapAt(slotCenter(tester, 0));
      await tester.pumpAndSettle();
      expect(taps, [4]);
    });

    testWidgets('dragging leftward moves toward higher indexes',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        Harness(textDirection: TextDirection.rtl, onTap: taps.add),
      );

      // Logical 0 is visual slot 4. Drag to visual slot 2, which is logical 2.
      await dragAcross(tester, slotCenter(tester, 4), slotCenter(tester, 2));
      await tester.pumpAndSettle();
      expect(taps, [2]);
      expect(indicatorPosition(tester), 2.0);
    });
  });
}
