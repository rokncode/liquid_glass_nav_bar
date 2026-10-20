/// An iOS 26 "Liquid Glass" style floating tab bar for Flutter.
///
/// The bar is a frosted, capsule-shaped surface that floats above your
/// content. It shrinks while the user scrolls down, expands again when they
/// scroll up, and lets them press and drag a glass "lens" across the tabs.
/// When they let go, the lens springs to the nearest tab.
///
/// Start with [LiquidGlassNavBar]. Use [LiquidGlassNavStyle] to change how it
/// looks.
library;

export 'src/nav_badge.dart' show NavBadge, NavBadgePosition;
export 'src/nav_bar.dart' show LiquidGlassNavBar, ShrinkMode;
export 'src/nav_bar_controller.dart' show LiquidGlassNavBarController;
export 'src/nav_item.dart' show LiquidGlassNavItem;
export 'src/nav_style.dart' show LiquidGlassNavStyle, NavLabelBehavior;
