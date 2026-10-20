import 'package:flutter/widgets.dart';

import 'nav_badge.dart';

/// One tab in a `LiquidGlassNavBar`.
///
/// Use the default constructor for an icon tab, or
/// [LiquidGlassNavItem.custom] for any widget, such as a profile picture:
///
/// ```dart
/// LiquidGlassNavItem(
///   icon: Icons.home_outlined,
///   activeIcon: Icons.home,
///   label: 'Home',
///   badge: NavBadge.dot(),
/// )
///
/// LiquidGlassNavItem.custom(
///   child: CircleAvatar(backgroundImage: NetworkImage(url)),
///   label: 'Profile',
/// )
/// ```
@immutable
class LiquidGlassNavItem {
  /// Creates a tab that shows [icon], or [activeIcon] when it is selected.
  const LiquidGlassNavItem({
    required IconData this.icon,
    this.activeIcon,
    this.label,
    this.badge,
    this.semanticLabel,
  })  : child = null,
        activeChild = null;

  /// Creates a tab that shows any widget, such as a `CircleAvatar`.
  ///
  /// [child] is sized to a square of the bar's current icon size, so it
  /// shrinks along with the bar. An `IconTheme` with the current icon color
  /// is provided, so `Icon` widgets inside it are tinted for you.
  const LiquidGlassNavItem.custom({
    required Widget this.child,
    this.activeChild,
    this.label,
    this.badge,
    this.semanticLabel,
  })  : icon = null,
        activeIcon = null;

  /// The icon shown when the tab is not selected.
  final IconData? icon;

  /// The icon shown when the tab is selected. Defaults to [icon].
  final IconData? activeIcon;

  /// The widget shown by a custom tab when it is not selected.
  final Widget? child;

  /// The widget shown by a custom tab when it is selected. Defaults to
  /// [child].
  final Widget? activeChild;

  /// The text under the icon (if labels are on). It is also used as the
  /// accessibility label when [semanticLabel] is null.
  final String? label;

  /// An optional badge (a dot or a count) shown on the icon.
  final NavBadge? badge;

  /// The label read by screen readers. Defaults to [label].
  final String? semanticLabel;

  /// Whether this tab was made with [LiquidGlassNavItem.custom].
  bool get isCustom => child != null;
}
