import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Maps between tab positions and horizontal pixels inside the bar.
///
/// A tab position is a *logical* index, as a double: `0.0` is the first item
/// in `items`, and `1.5` is halfway between the second and third items. In
/// RTL layouts logical index 0 sits at the right edge, so every conversion
/// goes through [visualSlot].
@immutable
class NavBarGeometry {
  /// Creates the geometry for a bar [width] pixels wide.
  const NavBarGeometry({
    required this.width,
    required this.itemCount,
    required this.padding,
    required this.isRtl,
  }) : assert(itemCount > 0);

  /// The width of the whole bar.
  final double width;

  /// How many tabs there are.
  final int itemCount;

  /// The horizontal padding between the bar's edge and the first or last
  /// slot.
  final double padding;

  /// Whether logical index 0 is on the right.
  final bool isRtl;

  /// The width of one tab slot.
  double get slotWidth => math.max(0, width - 2 * padding) / itemCount;

  /// The slot, counted from the left, that [logical] falls in.
  double visualSlot(double logical) =>
      isRtl ? (itemCount - 1) - logical : logical;

  /// The x coordinate of the center of the tab at [logical].
  double centerXFor(double logical) =>
      padding + (visualSlot(logical) + 0.5) * slotWidth;

  /// The logical tab position under the x coordinate [dx]. Not clamped.
  double logicalFromDx(double dx) {
    if (slotWidth == 0) return 0;
    final visual = (dx - padding) / slotWidth - 0.5;
    return isRtl ? (itemCount - 1) - visual : visual;
  }

  /// The index of the tab nearest to the x coordinate [dx].
  int indexFromDx(double dx) => nearestIndex(logicalFromDx(dx));

  /// The valid tab index nearest to [logical].
  int nearestIndex(double logical) =>
      logical.round().clamp(0, itemCount - 1).toInt();

  /// Turns a speed in pixels per second (positive to the right) into tab
  /// positions per second (positive toward higher indexes).
  double logicalVelocity(double pixelsPerSecond) {
    if (slotWidth == 0) return 0;
    final v = pixelsPerSecond / slotWidth;
    return isRtl ? -v : v;
  }

  /// Lets [logical] go past the first and last tab, with increasing
  /// resistance, but never more than [limit] slots.
  double rubberBand(double logical, {double limit = 0.3}) {
    final last = (itemCount - 1).toDouble();
    if (logical < 0) return -limit * (1 - math.exp(logical / limit));
    if (logical > last) {
      return last + limit * (1 - math.exp(-(logical - last) / limit));
    }
    return logical;
  }

  @override
  bool operator ==(Object other) =>
      other is NavBarGeometry &&
      other.width == width &&
      other.itemCount == itemCount &&
      other.padding == padding &&
      other.isRtl == isRtl;

  @override
  int get hashCode => Object.hash(width, itemCount, padding, isRtl);
}
