import 'package:flutter/widgets.dart';

/// Which corner of the icon a [NavBadge] sits on.
///
/// "End" follows the reading direction: it is the right side in LTR layouts
/// and the left side in RTL layouts.
enum NavBadgePosition {
  /// The top corner on the end side. Most apps use this.
  topEnd,

  /// The bottom corner on the end side. Instagram uses this for its red dots.
  bottomEnd,
}

/// A badge shown on a `LiquidGlassNavItem`: a dot, a count, or short text.
@immutable
class NavBadge {
  /// A small dot that says "something new" without a number.
  const NavBadge.dot({
    this.color,
    this.size = 8,
    this.position = NavBadgePosition.topEnd,
  })  : count = null,
        text = null,
        maxCount = 99,
        textColor = null;

  /// A pill with a number in it. Counts above [maxCount] show as `99+`.
  ///
  /// A [count] of zero or less hides the badge, so you can pass an unread
  /// count straight in.
  const NavBadge.count(
    int this.count, {
    this.maxCount = 99,
    this.color,
    this.textColor,
    this.position = NavBadgePosition.topEnd,
  })  : text = null,
        size = 16;

  /// A pill with short text in it, such as `'NEW'`.
  const NavBadge.text(
    String this.text, {
    this.color,
    this.textColor,
    this.position = NavBadgePosition.topEnd,
  })  : count = null,
        maxCount = 99,
        size = 16;

  /// The number shown by [NavBadge.count].
  final int? count;

  /// The text shown by [NavBadge.text].
  final String? text;

  /// The largest count shown as-is. Larger counts show as `'$maxCount+'`.
  final int maxCount;

  /// The badge color. If null, `LiquidGlassNavStyle.badgeColor` is used.
  final Color? color;

  /// The text color. If null, `LiquidGlassNavStyle.badgeTextColor` is used.
  final Color? textColor;

  /// For a dot, its diameter. For a pill, its minimum height and width.
  final double size;

  /// Which corner of the icon the badge sits on.
  final NavBadgePosition position;

  /// Whether this is a dot badge with no text.
  bool get isDot => count == null && text == null;

  /// Whether the badge should be painted at all.
  bool get isVisible => count == null || count! > 0;

  /// The text the badge shows, or null for a dot.
  String? get label {
    if (text != null) return text;
    if (count == null) return null;
    return count! > maxCount ? '$maxCount+' : '$count';
  }

  @override
  bool operator ==(Object other) =>
      other is NavBadge &&
      other.count == count &&
      other.text == text &&
      other.maxCount == maxCount &&
      other.color == color &&
      other.textColor == textColor &&
      other.size == size &&
      other.position == position;

  @override
  int get hashCode =>
      Object.hash(count, text, maxCount, color, textColor, size, position);
}

/// Draws a [NavBadge]. Used inside the nav bar.
class NavBadgeView extends StatelessWidget {
  /// Creates the widget that draws [badge].
  const NavBadgeView({
    super.key,
    required this.badge,
    required this.color,
    required this.textColor,
  });

  /// The badge to draw.
  final NavBadge badge;

  /// The color used when the badge doesn't set one.
  final Color color;

  /// The text color used when the badge doesn't set one.
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (!badge.isVisible) return const SizedBox.shrink();
    final fill = badge.color ?? color;
    final label = badge.label;
    if (label == null) {
      return Container(
        width: badge.size,
        height: badge.size,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      );
    }
    return Container(
      constraints: BoxConstraints(minWidth: badge.size, minHeight: badge.size),
      padding: const EdgeInsets.symmetric(horizontal: 4.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(badge.size / 2),
      ),
      child: Text(
        label,
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          color: badge.textColor ?? textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
