import 'package:flutter/widgets.dart';

import 'nav_badge.dart';
import 'nav_item.dart';
import 'nav_style.dart';

/// Draws one tab: its icon (or custom widget), badge, and optional label.
///
/// It rebuilds from [animation], which carries the indicator's position and
/// press state. That lets the icon nearest the indicator turn active, and the
/// icon under a dragged lens grow, without rebuilding the rest of the bar.
class NavItemView extends StatelessWidget {
  /// Creates the view for the tab at [index].
  const NavItemView({
    super.key,
    required this.item,
    required this.index,
    required this.style,
    required this.iconSize,
    required this.expandedFactor,
    required this.animation,
    required this.position,
    required this.press,
    required this.isSelected,
    required this.onSemanticTap,
  });

  /// The tab to draw.
  final LiquidGlassNavItem item;

  /// The tab's index in the bar.
  final int index;

  /// The bar's style.
  final LiquidGlassNavStyle style;

  /// The icon size for the bar's current shrink state.
  final double iconSize;

  /// 1 when the bar is fully expanded, 0 when it is fully compact. Labels
  /// fade and collapse along with it.
  final double expandedFactor;

  /// Fires whenever [position] or [press] changes.
  final Listenable animation;

  /// The indicator's current logical position.
  final ValueGetter<double> position;

  /// The current lens press amount.
  final ValueGetter<double> press;

  /// Whether this is the bar's `currentIndex`. Used for accessibility.
  final bool isSelected;

  /// Called when a screen reader activates the tab.
  final VoidCallback onSemanticTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      label: item.semanticLabel ?? item.label,
      onTap: onSemanticTap,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final pos = position();
    final proximity = (1 - (pos - index).abs()).clamp(0.0, 1.0);
    final active = pos.round() == index;
    final color = Color.lerp(style.iconColor, style.activeIconColor, proximity)!;
    final lens = press().clamp(0.0, 1.0);
    final scale = 1 + (style.lensIconScale - 1) * lens * proximity;

    Widget icon = item.isCustom
        ? IconTheme.merge(
            data: IconThemeData(color: color, size: iconSize),
            child: SizedBox.square(
              dimension: iconSize,
              child: active ? (item.activeChild ?? item.child!) : item.child!,
            ),
          )
        : Icon(
            active ? (item.activeIcon ?? item.icon) : item.icon,
            size: iconSize,
            color: color,
          );

    final badge = item.badge;
    if (badge != null && badge.isVisible) {
      final dot = badge.isDot;
      // Dots sit on the icon's corner. Pills hang a little further out so
      // the number stays readable.
      final double inset = dot ? -1 : -6;
      icon = Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          PositionedDirectional(
            end: inset,
            top: badge.position == NavBadgePosition.topEnd ? inset : null,
            bottom: badge.position == NavBadgePosition.bottomEnd ? inset : null,
            child: NavBadgeView(
              badge: badge,
              color: style.badgeColor,
              textColor: style.badgeTextColor,
            ),
          ),
        ],
      );
    }

    if (scale != 1) icon = Transform.scale(scale: scale, child: icon);

    final label = item.label;
    if (!style.labelsEnabled || label == null || expandedFactor == 0) {
      return Center(child: icon);
    }

    final labelOpacity = expandedFactor *
        (style.labelBehavior == NavLabelBehavior.selectedOnly ? proximity : 1);

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: expandedFactor,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Opacity(
                    opacity: labelOpacity.clamp(0.0, 1.0),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style.labelStyle.copyWith(color: color),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
