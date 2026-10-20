import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_floating_tab_bar/liquid_glass_floating_tab_bar.dart';

import 'helpers.dart';

void main() {
  // The default style caps the bar at 520 wide. On the 800-wide test screen,
  // that means 520 expanded and 520 - 2 * (48 - 16) = 456 compact.
  const expandedSize = Size(520, 64);
  const compactSize = Size(456, 52);

  group('shrink on scroll', () {
    testWidgets('scrolling down shrinks, scrolling up expands',
        (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(Harness(scrollController: scroll));
      expect(barRect(tester).size, expandedSize);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(barRect(tester).size, compactSize);
      expect(tester.getSize(find.byIcon(Icons.home)), const Size(22, 22));

      await tester.drag(find.byType(ListView), const Offset(0, 100));
      await tester.pumpAndSettle();
      expect(barRect(tester).size, expandedSize);
      expect(tester.getSize(find.byIcon(Icons.home)), const Size(26, 26));
    });

    testWidgets('scrolling less than the threshold does nothing',
        (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(Harness(scrollController: scroll));

      scroll.jumpTo(100);
      await tester.pump();
      scroll.jumpTo(108);
      await tester.pumpAndSettle();
      scroll.jumpTo(102);
      await tester.pumpAndSettle();
      expect(barRect(tester).size, expandedSize);

      scroll.jumpTo(130);
      await tester.pumpAndSettle();
      expect(barRect(tester).size, compactSize);
    });

    testWidgets('the bar box keeps its height, so the Scaffold never relayouts',
        (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(Harness(scrollController: scroll));
      final before = tester.getSize(find.byType(LiquidGlassNavBar));

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(LiquidGlassNavBar)), before);
    });

    testWidgets('tapping the compact bar expands it and selects the tab',
        (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final taps = <int>[];
      await tester.pumpWidget(
        Harness(scrollController: scroll, onTap: taps.add),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pumpAndSettle();
      expect(barRect(tester).size, expandedSize);
      expect(taps, [2]);
    });

    testWidgets('with selectOnCompactTap off, the first tap only expands',
        (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final taps = <int>[];
      await tester.pumpWidget(Harness(
        scrollController: scroll,
        selectOnCompactTap: false,
        onTap: taps.add,
      ));
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pumpAndSettle();
      expect(barRect(tester).size, expandedSize);
      expect(taps, isEmpty);
    });

    testWidgets('starting a drag on the compact bar expands it',
        (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(Harness(scrollController: scroll));
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final gesture = await dragAcross(
        tester,
        slotCenter(tester, 0),
        slotCenter(tester, 1),
        release: false,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(barRect(tester).size, expandedSize);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a controller fed by a NotificationListener works too',
        (tester) async {
      final controller = LiquidGlassNavBarController();
      await tester.pumpWidget(Harness(controller: controller));
      expect(controller.isAttached, isTrue);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(barRect(tester).size, compactSize);
      expect(controller.isCompact, isTrue);

      controller.expand();
      await tester.pumpAndSettle();
      expect(barRect(tester).size, expandedSize);
      expect(controller.isCompact, isFalse);
    });

    testWidgets('continuous mode follows the scroll, then settles',
        (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(Harness(
        scrollController: scroll,
        shrinkMode: ShrinkMode.continuous,
      ));

      scroll.jumpTo(100);
      await tester.pump();
      scroll.jumpTo(160); // half of the default 120px extent
      await tester.pump();
      expect(barRect(tester).height, closeTo(58, 0.01));

      // Once scrolling has been idle for 150ms, the bar settles on the
      // closer state.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(barRect(tester).size, compactSize);
    });

    testWidgets('does nothing when shrinking is turned off', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        Harness(scrollController: scroll, enableShrinkOnScroll: false),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(barRect(tester).size, expandedSize);
    });
  });

  group('layout', () {
    testWidgets('sits above the bottom safe area plus the margin',
        (tester) async {
      await tester.pumpWidget(const Harness(bottomPadding: 34));
      expect(barRect(tester).bottom, 600 - 34 - 8);
      expect(barRect(tester).center.dx, 400);
    });

    testWidgets('works as a Stack overlay and lets taps beside it through',
        (tester) async {
      var backgroundTaps = 0;
      final taps = <int>[];
      await tester.pumpWidget(MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => backgroundTaps++,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LiquidGlassNavBar(
                items: buildItems(),
                currentIndex: 0,
                onTap: taps.add,
              ),
            ),
          ],
        ),
      ));

      final bar = barRect(tester);
      await tester.tapAt(Offset(bar.left - 40, bar.center.dy));
      await tester.tapAt(Offset(bar.center.dx, bar.top - 4));
      expect(backgroundTaps, 2);

      await tester.tap(find.byIcon(Icons.search_outlined));
      await tester.pumpAndSettle();
      expect(taps, [3]);
      expect(backgroundTaps, 2);
    });

    testWidgets('fills the width when maxWidth is cleared', (tester) async {
      await tester.pumpWidget(Harness(
        style: const LiquidGlassNavStyle.dark().copyWith(clearMaxWidth: true),
      ));
      expect(barRect(tester).width, 800 - 2 * 16);
    });

    testWidgets('picks the light style in a light theme', (tester) async {
      await tester.pumpWidget(const Harness());
      expect(indicatorOf(tester).style, const LiquidGlassNavStyle.light());
    });
  });

  group('items', () {
    testWidgets('count badges cap at 99+ and dots render', (tester) async {
      await tester.pumpWidget(const Harness());
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('custom children are sized to the icon size', (tester) async {
      await tester.pumpWidget(const Harness());
      expect(tester.getSize(find.byKey(avatarKey)), const Size(26, 26));
    });

    testWidgets('labels follow showLabels and labelBehavior', (tester) async {
      await tester.pumpWidget(const Harness());
      expect(find.text('Home'), findsNothing);

      await tester.pumpWidget(Harness(
        style: const LiquidGlassNavStyle.dark().copyWith(showLabels: true),
      ));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);

      await tester.pumpWidget(Harness(
        style: const LiquidGlassNavStyle.dark().copyWith(
          showLabels: true,
          labelBehavior: NavLabelBehavior.never,
        ),
      ));
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('selectedOnly hides the labels of other tabs',
        (tester) async {
      await tester.pumpWidget(Harness(
        style: const LiquidGlassNavStyle.dark().copyWith(
          showLabels: true,
          labelBehavior: NavLabelBehavior.selectedOnly,
        ),
      ));
      double opacityOf(String label) => tester
          .widget<Opacity>(
            find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
          )
          .opacity;
      expect(opacityOf('Home'), 1);
      expect(opacityOf('Search'), 0);
    });

    testWidgets('labels disappear when the bar is compact', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(Harness(
        scrollController: scroll,
        style: const LiquidGlassNavStyle.dark().copyWith(showLabels: true),
      ));
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('tabs are buttons with labels and a selected state',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const Harness());

      expect(
        tester.getSemantics(find.bySemanticsLabel('Home')),
        isSemantics(isButton: true, isSelected: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Search')),
        isSemantics(isButton: true, isSelected: false),
      );
      handle.dispose();
    });
  });
}
