import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_nav_bar/liquid_glass_nav_bar.dart';
import 'package:liquid_glass_nav_bar/src/glass_surface.dart';
import 'package:liquid_glass_nav_bar/src/indicator_painter.dart';

const avatarKey = Key('avatar');

/// Five tabs: four icons (one with a count badge) and an avatar with a dot.
List<LiquidGlassNavItem> buildItems() => const [
      LiquidGlassNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
      ),
      LiquidGlassNavItem(
        icon: Icons.play_circle_outline,
        activeIcon: Icons.play_circle,
        label: 'Reels',
      ),
      LiquidGlassNavItem(
        icon: Icons.send_outlined,
        activeIcon: Icons.send,
        label: 'Messages',
        badge: NavBadge.count(120),
      ),
      LiquidGlassNavItem(
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        label: 'Search',
      ),
      LiquidGlassNavItem.custom(
        child: ColoredBox(key: avatarKey, color: Colors.orange),
        label: 'Profile',
        badge: NavBadge.dot(position: NavBadgePosition.bottomEnd),
      ),
    ];

/// A Scaffold with a long list behind the bar. It owns `currentIndex` the way
/// a real app would.
class Harness extends StatefulWidget {
  const Harness({
    super.key,
    this.initialIndex = 0,
    this.followTaps = true,
    this.textDirection = TextDirection.ltr,
    this.scrollController,
    this.controller,
    this.style,
    this.enableDragToSwitch = true,
    this.enableHaptics = true,
    this.enableShrinkOnScroll = true,
    this.shrinkMode = ShrinkMode.threshold,
    this.selectOnCompactTap = true,
    this.bottomPadding = 0,
    this.onTap,
    this.onTabChanged,
  });

  final int initialIndex;
  final bool followTaps;
  final TextDirection textDirection;
  final ScrollController? scrollController;
  final LiquidGlassNavBarController? controller;
  final LiquidGlassNavStyle? style;
  final bool enableDragToSwitch;
  final bool enableHaptics;
  final bool enableShrinkOnScroll;
  final ShrinkMode shrinkMode;
  final bool selectOnCompactTap;
  final double bottomPadding;
  final ValueChanged<int>? onTap;
  final ValueChanged<int>? onTabChanged;

  @override
  State<Harness> createState() => HarnessState();
}

class HarnessState extends State<Harness> {
  late int index = widget.initialIndex;

  void setIndex(int value) => setState(() => index = value);

  @override
  Widget build(BuildContext context) {
    Widget body = ListView.builder(
      controller: widget.scrollController,
      itemCount: 200,
      itemBuilder: (_, i) => SizedBox(height: 60, child: Text('Row $i')),
    );
    final controller = widget.controller;
    if (controller != null) {
      body = NotificationListener<ScrollNotification>(
        onNotification: controller.handleScrollNotification,
        child: body,
      );
    }
    return MaterialApp(
      home: Directionality(
        textDirection: widget.textDirection,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(bottom: widget.bottomPadding),
            ),
            child: Scaffold(
              extendBody: true,
              body: body,
              bottomNavigationBar: LiquidGlassNavBar(
                items: buildItems(),
                currentIndex: index,
                scrollController: widget.scrollController,
                controller: controller,
                style: widget.style,
                enableDragToSwitch: widget.enableDragToSwitch,
                enableHaptics: widget.enableHaptics,
                enableShrinkOnScroll: widget.enableShrinkOnScroll,
                shrinkMode: widget.shrinkMode,
                selectOnCompactTap: widget.selectOnCompactTap,
                onTap: (i) {
                  widget.onTap?.call(i);
                  if (widget.followTaps) setIndex(i);
                },
                onTabChanged: widget.onTabChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IndicatorPainter indicatorOf(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.painter)
    .whereType<IndicatorPainter>()
    .single;

double indicatorPosition(WidgetTester tester) =>
    indicatorOf(tester).position();

Rect barRect(WidgetTester tester) => tester.getRect(find.byType(GlassSurface));

/// The center of tab [visualSlot], counted from the left edge of the bar.
Offset slotCenter(
  WidgetTester tester,
  double visualSlot, {
  int count = 5,
  double padding = 6,
}) {
  final rect = barRect(tester);
  final slot = (rect.width - 2 * padding) / count;
  return Offset(rect.left + padding + slot * (visualSlot + 0.5), rect.center.dy);
}

double slotWidth(WidgetTester tester, {int count = 5, double padding = 6}) =>
    (barRect(tester).width - 2 * padding) / count;

/// Moves a pointer from [from] to [to] in [steps] frames. Returns the gesture
/// still held down unless [release] is true.
Future<TestGesture> dragAcross(
  WidgetTester tester,
  Offset from,
  Offset to, {
  int steps = 24,
  bool release = true,
}) async {
  final gesture = await tester.startGesture(from);
  for (var i = 1; i <= steps; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / steps)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  if (release) await gesture.up();
  return gesture;
}

/// Records every haptic request sent to the platform.
List<String> recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') {
      calls.add(call.arguments as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}
