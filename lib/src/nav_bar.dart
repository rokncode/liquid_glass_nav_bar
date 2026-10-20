import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'geometry.dart';
import 'glass_surface.dart';
import 'indicator_painter.dart';
import 'nav_bar_controller.dart';
import 'nav_item.dart';
import 'nav_item_view.dart';
import 'nav_style.dart';
import 'scroll_shrink.dart';

/// How a [LiquidGlassNavBar] follows scrolling.
enum ShrinkMode {
  /// After scrolling `shrinkThreshold` pixels the same way, the bar animates
  /// fully to compact or fully to expanded. This is what iOS does.
  threshold,

  /// The bar follows the scroll position frame by frame, and is fully
  /// compact after `shrinkScrollExtent` pixels. When scrolling stops, it
  /// settles on whichever state is closer.
  continuous,
}

/// How far, in tabs, the spring may overshoot past the target tab.
const double _kMaxOvershoot = 0.22;

/// How far, in tabs, the indicator can be dragged past the first or last tab.
const double _kEdgeOverscroll = 0.3;

/// The fastest release speed, in tabs per second, handed to the spring.
const double _kMaxReleaseVelocity = 8;

/// How long the lens takes to catch up when a drag starts away from it.
const Duration _kCatchUpDuration = Duration(milliseconds: 140);

/// A floating, frosted-glass tab bar in the style of iOS 26 "Liquid Glass".
///
/// * The bar is a blurred, tinted capsule with a highlighted edge and a soft
///   shadow, and it respects the bottom safe area.
/// * A lighter capsule sits behind the selected tab. Tapping another tab
///   springs the capsule there.
/// * Pressing and dragging across the bar turns the capsule into a larger,
///   clearer lens that follows the finger and stretches with speed. On
///   release it springs to the nearest tab and calls [onTap].
/// * With [enableShrinkOnScroll], the bar shrinks when the user scrolls down
///   and grows back when they scroll up.
///
/// The bar is *controlled*: it shows [currentIndex]. Update [currentIndex]
/// from [onTap] (or [onTabChanged]). If you don't, the indicator springs back
/// to the old tab.
///
/// ```dart
/// Scaffold(
///   extendBody: true, // so content scrolls behind the glass
///   body: ListView(controller: scrollController, children: ...),
///   bottomNavigationBar: LiquidGlassNavBar(
///     currentIndex: index,
///     onTap: (i) => setState(() => index = i),
///     scrollController: scrollController,
///     items: const [
///       LiquidGlassNavItem(icon: Icons.home_outlined, activeIcon: Icons.home),
///       LiquidGlassNavItem(icon: Icons.search),
///     ],
///   ),
/// )
/// ```
///
/// The bar also works in a `Stack`. Place it with
/// `Positioned(left: 0, right: 0, bottom: 0, child: ...)`. Its box is always
/// the expanded height, so the `Scaffold` never has to lay out again while
/// the bar shrinks. Taps on the empty space around the capsule pass through
/// to the content below.
class LiquidGlassNavBar extends StatefulWidget {
  /// Creates a liquid glass nav bar.
  const LiquidGlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    this.onTap,
    this.onTabChanged,
    this.scrollController,
    this.controller,
    this.style,
    this.enableShrinkOnScroll = true,
    this.enableDragToSwitch = true,
    this.enableHaptics = true,
    this.shrinkMode = ShrinkMode.threshold,
    this.shrinkThreshold = 10,
    this.shrinkScrollExtent = 120,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeOutCubic,
    this.spring = defaultSpring,
    this.selectOnCompactTap = true,
  })  : assert(items.length >= 2, 'A nav bar needs at least two items.'),
        assert(currentIndex >= 0 && currentIndex < items.length),
        assert(shrinkThreshold >= 0),
        assert(shrinkScrollExtent > 0);

  /// The default spring used when the indicator settles on a tab.
  ///
  /// Its damping ratio is about 0.77, which gives a small bounce of roughly
  /// 2% past the target before settling.
  static const SpringDescription defaultSpring =
      SpringDescription(mass: 1, stiffness: 380, damping: 30);

  /// The tabs, at least two. Five or fewer fit best on a phone.
  final List<LiquidGlassNavItem> items;

  /// The index of the selected tab.
  final int currentIndex;

  /// Called when the user taps a tab, or releases a drag over one. It fires
  /// even when the tab is already selected, which you can use for
  /// "scroll to top on re-tap".
  final ValueChanged<int>? onTap;

  /// Called when a tap or drag picks a tab other than [currentIndex].
  final ValueChanged<int>? onTabChanged;

  /// A scroll controller to watch for scroll-to-shrink.
  ///
  /// It must be attached to exactly one scroll view. If your tabs each have
  /// their own scroll view, use [controller] and a `NotificationListener`
  /// instead.
  final ScrollController? scrollController;

  /// Lets you shrink or expand the bar yourself, and forward scroll
  /// notifications to it.
  final LiquidGlassNavBarController? controller;

  /// The look of the bar. If null, the bar uses [LiquidGlassNavStyle.light]
  /// or [LiquidGlassNavStyle.dark] based on `Theme.of(context).brightness`.
  final LiquidGlassNavStyle? style;

  /// Whether scrolling down shrinks the bar.
  final bool enableShrinkOnScroll;

  /// Whether a horizontal drag across the bar moves the lens between tabs.
  final bool enableDragToSwitch;

  /// Whether to play a selection click when a drag moves onto a new tab.
  final bool enableHaptics;

  /// How the bar follows scrolling. See [ShrinkMode].
  final ShrinkMode shrinkMode;

  /// How many pixels the user must scroll the same way before the bar
  /// changes state in [ShrinkMode.threshold].
  final double shrinkThreshold;

  /// How many pixels of scrolling take the bar from expanded to compact in
  /// [ShrinkMode.continuous].
  final double shrinkScrollExtent;

  /// How long the shrink and expand animation takes.
  final Duration animationDuration;

  /// The curve of the shrink and expand animation.
  final Curve animationCurve;

  /// The spring that moves the indicator to a tab after a tap or a drag.
  final SpringDescription spring;

  /// Whether tapping a tab on a compact bar also selects it. When false, the
  /// first tap only expands the bar.
  final bool selectOnCompactTap;

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar>
    with TickerProviderStateMixin
    implements LiquidGlassNavBarDelegate {
  /// The indicator position, as a logical tab index.
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.currentIndex.toDouble(),
  );

  /// How far the indicator has turned into a lens (0 to 1).
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 280),
  );
  late final CurvedAnimation _pressCurve = CurvedAnimation(
    parent: _press,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInCubic,
  );

  /// The drag-speed stretch (0 to 1). It fades out on its own when the
  /// finger stops moving.
  late final AnimationController _stretch = AnimationController(vsync: this);

  /// 0 when the bar is expanded, 1 when it is compact.
  late final AnimationController _shrink = AnimationController(vsync: this);

  late final Listenable _indicatorListenable =
      Listenable.merge([_position, _pressCurve, _stretch]);
  late final Listenable _itemListenable =
      Listenable.merge([_position, _pressCurve]);

  late final ScrollShrinkTracker _tracker =
      ScrollShrinkTracker(threshold: widget.shrinkThreshold);

  /// The geometry from the last layout. Gesture handlers use it to turn
  /// pointer positions into tab positions.
  NavBarGeometry? _geometry;

  bool _dragging = false;
  bool _catchingUp = false;
  Duration _catchUpEnd = Duration.zero;
  final Stopwatch _clock = Stopwatch()..start();
  Duration _lastDragTime = Duration.zero;
  double _dragVelocity = 0;
  int _lastDragIndex = 0;

  /// The tab the indicator is currently heading to. Set in [initState], not
  /// with a lazy initializer: a lazy one would first run in [didUpdateWidget]
  /// and read the *new* widget's index.
  late int _targetIndex;

  /// Limits on the drawn position while the spring runs, so it can't swing
  /// more than [_kMaxOvershoot] past either end of its path.
  double _springLow = double.negativeInfinity;
  double _springHigh = double.infinity;

  /// The direction the shrink animation is heading (0 or 1), or null when
  /// it isn't animating.
  double? _shrinkTarget;

  double? _lastScrollPixels;
  Timer? _scrollIdleTimer;

  int get _count => widget.items.length;

  // ---------------------------------------------------------------------------
  // Lifecycle

  @override
  void initState() {
    super.initState();
    _targetIndex = widget.currentIndex;
    widget.controller?.attach(this);
    widget.scrollController?.addListener(_handleScrollControllerTick);
  }

  @override
  void didUpdateWidget(LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_handleScrollControllerTick);
      widget.scrollController?.addListener(_handleScrollControllerTick);
      _lastScrollPixels = null;
    }
    _tracker.threshold = widget.shrinkThreshold;
    if (!widget.enableShrinkOnScroll && oldWidget.enableShrinkOnScroll) {
      expand();
    }
    if (widget.items.length != oldWidget.items.length) {
      final clamped = _targetIndex.clamp(0, _count - 1);
      _position.value = _position.value.clamp(0.0, _count - 1.0);
      _targetIndex = clamped;
    }
    if (!_dragging && widget.currentIndex != _targetIndex) {
      _springTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(this);
    widget.scrollController?.removeListener(_handleScrollControllerTick);
    _scrollIdleTimer?.cancel();
    _pressCurve.dispose();
    _position.dispose();
    _press.dispose();
    _stretch.dispose();
    _shrink.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Indicator values

  /// The position used for drawing. It is held inside the spring's
  /// overshoot limits and the drag rubber band.
  double get _displayPosition {
    final low = math.max(_springLow, -_kEdgeOverscroll);
    final high = math.min(_springHigh, _count - 1 + _kEdgeOverscroll);
    return _position.value.clamp(low, high);
  }

  double get _pressValue => _pressCurve.value;

  double get _stretchValue {
    final springSpeed = (!_dragging && _position.isAnimating)
        ? _position.velocity.abs()
        : 0.0;
    return math.max(_stretch.value, _stretchForSpeed(springSpeed));
  }

  /// Turns a speed in tabs per second into a stretch amount from 0 to 1.
  static double _stretchForSpeed(double tabsPerSecond) =>
      (tabsPerSecond.abs() / 30).clamp(0.0, 1.0);

  void _springTo(int index, {double velocity = 0}) {
    final from = _position.value;
    final to = index.toDouble();
    _targetIndex = index;
    _springLow = math.min(from, to) - _kMaxOvershoot;
    _springHigh = math.max(from, to) + _kMaxOvershoot;
    _catchingUp = false;
    _position
        .animateWith(SpringSimulation(
          widget.spring,
          from,
          to,
          velocity,
          tolerance: const Tolerance(distance: 0.002, velocity: 0.02),
        ))
        .then((_) {
      // Land exactly on the tab once the spring is done.
      if (mounted && !_dragging && _targetIndex == index) {
        _position.value = to;
      }
    });
  }

  /// Springs to [index] and reports it, then checks that the parent kept it.
  void _select(int index, {double velocity = 0}) {
    final previous = widget.currentIndex;
    _springTo(index, velocity: velocity);
    widget.onTap?.call(index);
    if (index != previous) widget.onTabChanged?.call(index);

    // The bar is controlled. If the parent didn't switch to [index], spring
    // back to the tab it is still showing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _dragging) return;
      if (widget.currentIndex != _targetIndex) _springTo(widget.currentIndex);
    });
  }

  /// A short, subtle lens pop for taps, so they feel like the glass reacted.
  void _popLens() {
    _press
        .animateTo(0.35, duration: const Duration(milliseconds: 110))
        .then((_) {
      if (mounted && !_dragging) _press.reverse();
    });
  }

  // ---------------------------------------------------------------------------
  // Gestures

  void _handleTapUp(TapUpDetails details) {
    final geometry = _geometry;
    if (geometry == null) return;
    final wasCompact = _shrink.value > 0.5;
    expand();
    if (wasCompact && !widget.selectOnCompactTap) return;
    _popLens();
    _select(geometry.indexFromDx(details.localPosition.dx));
  }

  double _fingerPosition(NavBarGeometry geometry, double dx) => geometry
      .rubberBand(geometry.logicalFromDx(dx), limit: _kEdgeOverscroll);

  void _handleDragStart(DragStartDetails details) {
    final geometry = _geometry;
    if (geometry == null) return;
    expand();
    _dragging = true;
    _springLow = double.negativeInfinity;
    _springHigh = double.infinity;
    _position.stop();
    _press.forward();
    _dragVelocity = 0;
    _lastDragTime = details.sourceTimeStamp ?? _clock.elapsed;

    final finger = _fingerPosition(geometry, details.localPosition.dx);
    _lastDragIndex = geometry.nearestIndex(_position.value);
    if ((finger - _position.value).abs() > 0.5) {
      // The drag started on another tab. Glide the lens over instead of
      // jumping.
      _catchingUp = true;
      _catchUpEnd = _clock.elapsed + _kCatchUpDuration;
      _chase(finger);
    } else {
      _position.value = finger;
    }
    _maybeTick(geometry, finger);
  }

  /// Moves the lens toward [finger], finishing by [_catchUpEnd].
  void _chase(double finger) {
    final remaining = _catchUpEnd - _clock.elapsed;
    if (remaining < const Duration(milliseconds: 16)) {
      _catchingUp = false;
      _position.value = finger;
      return;
    }
    _position.animateTo(
      finger,
      duration: remaining,
      curve: Curves.easeOutCubic,
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final geometry = _geometry;
    if (!_dragging || geometry == null) return;
    final finger = _fingerPosition(geometry, details.localPosition.dx);
    if (_catchingUp) {
      _chase(finger);
    } else {
      _position.value = finger;
    }

    // Smooth the finger speed and turn it into stretch. The stretch then
    // fades back to zero on its own, so stopping mid-drag relaxes the lens.
    // Prefer the pointer event timestamps. Fall back to wall-clock time when
    // they're missing, such as for synthesized events.
    final now = details.sourceTimeStamp ?? _clock.elapsed;
    final dt = (now - _lastDragTime).inMicroseconds / 1e6;
    _lastDragTime = now;
    if (dt > 0 && geometry.slotWidth > 0) {
      final instant = details.delta.dx / geometry.slotWidth / dt;
      _dragVelocity = lerpDouble(_dragVelocity, instant, 0.4)!;
      _stretch.value = _stretchForSpeed(_dragVelocity);
      _stretch.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
    _maybeTick(geometry, finger);
  }

  void _maybeTick(NavBarGeometry geometry, double finger) {
    final index = geometry.nearestIndex(finger);
    if (index == _lastDragIndex) return;
    _lastDragIndex = index;
    if (widget.enableHaptics) HapticFeedback.selectionClick();
  }

  void _handleDragEnd(DragEndDetails details) {
    final geometry = _geometry;
    if (!_dragging || geometry == null) return;
    _dragging = false;
    _catchingUp = false;
    _press.reverse();
    _stretch.animateTo(0, duration: const Duration(milliseconds: 200));
    final velocity = geometry
        .logicalVelocity(details.velocity.pixelsPerSecond.dx)
        .clamp(-_kMaxReleaseVelocity, _kMaxReleaseVelocity);
    _select(geometry.nearestIndex(_position.value), velocity: velocity);
  }

  void _handleDragCancel() {
    if (!_dragging) return;
    _handleDragEnd(DragEndDetails(primaryVelocity: 0));
  }

  // ---------------------------------------------------------------------------
  // Shrink on scroll

  @override
  bool get isCompact =>
      _shrinkTarget != null ? _shrinkTarget == 1 : _shrink.value >= 0.5;

  @override
  void expand() => _animateShrink(0);

  @override
  void shrink() => _animateShrink(1);

  void _animateShrink(double target) {
    if (!mounted) return;
    if (_shrinkTarget == target && _shrink.isAnimating) return;
    if (!_shrink.isAnimating && _shrink.value == target) return;
    _tracker.reset();
    _shrinkTarget = target;
    _shrink
        .animateTo(
          target,
          duration: widget.animationDuration,
          curve: widget.animationCurve,
        )
        .whenCompleteOrCancel(() {
      if (_shrinkTarget == target) _shrinkTarget = null;
    });
  }

  void _handleScrollDelta(double delta, {required bool atStart}) {
    if (!widget.enableShrinkOnScroll || _dragging || !mounted) return;
    if (atStart) {
      expand();
      return;
    }
    switch (widget.shrinkMode) {
      case ShrinkMode.threshold:
        switch (_tracker.addDelta(delta)) {
          case ShrinkDirective.shrink:
            shrink();
          case ShrinkDirective.expand:
            expand();
          case ShrinkDirective.none:
            break;
        }
      case ShrinkMode.continuous:
        _shrinkTarget = null;
        _shrink.value =
            (_shrink.value + delta / widget.shrinkScrollExtent).clamp(0.0, 1.0);
    }
  }

  void _handleScrollIdle() {
    if (!mounted || widget.shrinkMode != ShrinkMode.continuous) return;
    final value = _shrink.value;
    if (value > 0 && value < 1) _animateShrink(value >= 0.5 ? 1 : 0);
  }

  void _handleScrollControllerTick() {
    final controller = widget.scrollController!;
    if (!controller.hasClients || controller.positions.length != 1) return;
    final position = controller.position;
    if (position.axis != Axis.vertical || !position.hasPixels) return;
    final pixels = position.pixels;
    final last = _lastScrollPixels;
    _lastScrollPixels = pixels;
    if (last == null) return;
    // Skip overscroll so an iOS bounce at the end of the list doesn't read as
    // scrolling back up.
    if (position.hasContentDimensions && position.outOfRange) {
      if (pixels <= position.minScrollExtent) expand();
      return;
    }
    final atStart = position.hasContentDimensions &&
        pixels <= position.minScrollExtent;
    _handleScrollDelta(pixels - last, atStart: atStart);

    if (widget.shrinkMode == ShrinkMode.continuous) {
      _scrollIdleTimer?.cancel();
      _scrollIdleTimer =
          Timer(const Duration(milliseconds: 150), _handleScrollIdle);
    }
  }

  @override
  void handleScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return;
    if (notification is ScrollEndNotification) {
      _handleScrollIdle();
      return;
    }
    if (notification is! ScrollUpdateNotification) return;
    final delta = notification.scrollDelta;
    if (delta == null) return;
    if (metrics.outOfRange) {
      if (metrics.pixels <= metrics.minScrollExtent) expand();
      return;
    }
    _handleScrollDelta(delta, atStart: metrics.pixels <= metrics.minScrollExtent);
  }

  // ---------------------------------------------------------------------------
  // Build

  LiquidGlassNavStyle _resolveStyle(BuildContext context) {
    final style = widget.style;
    if (style != null) return style;
    return Theme.of(context).brightness == Brightness.dark
        ? const LiquidGlassNavStyle.dark()
        : const LiquidGlassNavStyle.light();
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomGap = style.bottomMargin + bottomInset;

    // The box always has the expanded height, plus room for the lens to stick
    // out, so a Scaffold never lays out again while the bar shrinks.
    return SizedBox(
      height: style.height + style.lensOverflow + bottomGap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          return AnimatedBuilder(
            animation: _shrink,
            builder: (context, _) =>
                _buildBar(context, style, isRtl, available, bottomGap),
          );
        },
      ),
    );
  }

  Widget _buildBar(
    BuildContext context,
    LiquidGlassNavStyle style,
    bool isRtl,
    double available,
    double bottomGap,
  ) {
    final t = _shrink.value;
    var expandedWidth = math.max(0.0, available - 2 * style.horizontalMargin);
    if (style.maxWidth != null) {
      expandedWidth = math.min(expandedWidth, style.maxWidth!);
    }
    final compactWidth = math.max(
      _count * style.compactHeight * 0.9,
      expandedWidth -
          2 * (style.compactHorizontalMargin - style.horizontalMargin),
    );
    final width = math.min(
      available,
      lerpDouble(expandedWidth, compactWidth, t)!,
    );
    final height = lerpDouble(style.height, style.compactHeight, t)!;
    final iconSize = lerpDouble(style.iconSize, style.compactIconSize, t)!;

    final geometry = NavBarGeometry(
      width: width,
      itemCount: _count,
      padding: style.innerPadding,
      isRtl: isRtl,
    );
    // Saved for the gesture handlers. This is the geometry that was just
    // painted, so pointer positions line up with what the user sees.
    _geometry = geometry;

    final drag = widget.enableDragToSwitch;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomGap),
        child: SizedBox(
          width: width,
          height: height,
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _handleTapUp,
              onHorizontalDragStart: drag ? _handleDragStart : null,
              onHorizontalDragUpdate: drag ? _handleDragUpdate : null,
              onHorizontalDragEnd: drag ? _handleDragEnd : null,
              onHorizontalDragCancel: drag ? _handleDragCancel : null,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  GlassSurface(style: style),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: IndicatorPainter(
                        geometry: geometry,
                        style: style,
                        position: () => _displayPosition,
                        press: () => _pressValue,
                        stretch: () => _stretchValue,
                        repaint: _indicatorListenable,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: style.innerPadding),
                    child: Row(
                      children: [
                        for (var i = 0; i < _count; i++)
                          Expanded(
                            child: NavItemView(
                              item: widget.items[i],
                              index: i,
                              style: style,
                              iconSize: iconSize,
                              expandedFactor: 1 - t,
                              animation: _itemListenable,
                              position: () => _displayPosition,
                              press: () => _pressValue,
                              isSelected: i == widget.currentIndex,
                              onSemanticTap: () => _select(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
