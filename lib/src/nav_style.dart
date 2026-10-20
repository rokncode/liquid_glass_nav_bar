import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Controls when tab labels are shown under the icons.
///
/// This only applies when [LiquidGlassNavStyle.showLabels] is `true`. Labels
/// are always hidden while the bar is compact.
enum NavLabelBehavior {
  /// Every tab shows its label.
  always,

  /// Only the selected tab shows its label.
  selectedOnly,

  /// No tab shows a label.
  never,
}

/// The visual configuration of a `LiquidGlassNavBar`.
///
/// The default constructor gives the dark look. Use
/// [LiquidGlassNavStyle.light] or [LiquidGlassNavStyle.dark] as a starting
/// point and change single values with [copyWith]:
///
/// ```dart
/// LiquidGlassNavStyle.light().copyWith(blurSigma: 30, showLabels: true)
/// ```
///
/// If the bar is given no style, it picks [LiquidGlassNavStyle.light] or
/// [LiquidGlassNavStyle.dark] from the ambient `Theme` brightness.
@immutable
class LiquidGlassNavStyle with Diagnosticable {
  /// Creates a style. Values you leave out use the dark defaults.
  const LiquidGlassNavStyle({
    this.blurSigma = 20,
    this.backgroundColor = const Color(0x8C1C1C1E),
    this.borderColor = const Color(0x26FFFFFF),
    this.indicatorColor = const Color(0x2EFFFFFF),
    this.dragIndicatorColor = const Color(0x1AFFFFFF),
    this.lensHighlightColor = const Color(0x8CFFFFFF),
    this.iconColor = const Color(0xFFFFFFFF),
    this.activeIconColor = const Color(0xFFFFFFFF),
    this.badgeColor = const Color(0xFFFF3040),
    this.badgeTextColor = const Color(0xFFFFFFFF),
    this.shadowColor = const Color(0x40000000),
    this.shadowBlurRadius = 24,
    this.shadowOffset = const Offset(0, 8),
    this.height = 64,
    this.compactHeight = 52,
    this.iconSize = 26,
    this.compactIconSize = 22,
    this.horizontalMargin = 16,
    this.compactHorizontalMargin = 48,
    this.bottomMargin = 8,
    this.innerPadding = 6,
    this.maxWidth = 520,
    this.lensScale = 1.18,
    this.lensOverflow = 4,
    this.lensIconScale = 1.12,
    this.showLabels = false,
    this.labelStyle = const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    this.labelBehavior = NavLabelBehavior.always,
  })  : assert(blurSigma >= 0),
        assert(height > 0 && compactHeight > 0),
        assert(compactHeight <= height),
        assert(iconSize > 0 && compactIconSize > 0),
        assert(horizontalMargin >= 0 && compactHorizontalMargin >= 0),
        assert(innerPadding >= 0),
        assert(maxWidth == null || maxWidth > 0),
        assert(lensScale >= 1),
        assert(lensIconScale >= 1);

  /// The dark style: dark smoky glass and white icons.
  const factory LiquidGlassNavStyle.dark() = LiquidGlassNavStyle;

  /// The light style: milky glass and near-black icons.
  const LiquidGlassNavStyle.light({
    this.blurSigma = 20,
    this.backgroundColor = const Color(0x8CF9F9FB),
    this.borderColor = const Color(0xB3FFFFFF),
    this.indicatorColor = const Color(0x14000000),
    this.dragIndicatorColor = const Color(0x0A000000),
    this.lensHighlightColor = const Color(0xE6FFFFFF),
    this.iconColor = const Color(0xFF1C1C1E),
    this.activeIconColor = const Color(0xFF000000),
    this.badgeColor = const Color(0xFFFF3040),
    this.badgeTextColor = const Color(0xFFFFFFFF),
    this.shadowColor = const Color(0x24000000),
    this.shadowBlurRadius = 24,
    this.shadowOffset = const Offset(0, 8),
    this.height = 64,
    this.compactHeight = 52,
    this.iconSize = 26,
    this.compactIconSize = 22,
    this.horizontalMargin = 16,
    this.compactHorizontalMargin = 48,
    this.bottomMargin = 8,
    this.innerPadding = 6,
    this.maxWidth = 520,
    this.lensScale = 1.18,
    this.lensOverflow = 4,
    this.lensIconScale = 1.12,
    this.showLabels = false,
    this.labelStyle = const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    this.labelBehavior = NavLabelBehavior.always,
  });

  /// How strongly the content behind the bar is blurred (Gaussian sigma).
  final double blurSigma;

  /// The tint painted over the blurred backdrop. Keep it semi-transparent.
  final Color backgroundColor;

  /// The color of the 1px edge highlight at the top of the bar. The stroke
  /// fades to about a quarter of this opacity at the bottom edge.
  final Color borderColor;

  /// The fill of the selected-tab capsule when it is at rest.
  final Color indicatorColor;

  /// The fill of the capsule while it is being dragged as a lens. This is
  /// usually more transparent than [indicatorColor].
  final Color dragIndicatorColor;

  /// The rim and specular highlight drawn on the lens while it is dragged.
  final Color lensHighlightColor;

  /// The color of unselected icons and labels.
  final Color iconColor;

  /// The color of the selected icon and label.
  final Color activeIconColor;

  /// The default badge color. A single `NavBadge` can override it.
  final Color badgeColor;

  /// The default color of the text inside count and text badges.
  final Color badgeTextColor;

  /// The color of the soft shadow under the bar. Only the part outside the
  /// glass is painted, so it never darkens the glass itself.
  final Color shadowColor;

  /// The blur radius of the shadow under the bar.
  final double shadowBlurRadius;

  /// How far the shadow is offset from the bar.
  final Offset shadowOffset;

  /// The height of the bar when it is expanded.
  final double height;

  /// The height of the bar when it is compact (after scrolling down).
  final double compactHeight;

  /// The icon size when the bar is expanded.
  final double iconSize;

  /// The icon size when the bar is compact.
  final double compactIconSize;

  /// The gap between each side of the screen and the expanded bar.
  final double horizontalMargin;

  /// The gap between each side of the screen and the compact bar.
  final double compactHorizontalMargin;

  /// The gap between the bar and the bottom safe-area inset.
  final double bottomMargin;

  /// The padding between the bar's edge and the indicator, on all sides.
  final double innerPadding;

  /// The widest the bar can get, which keeps it a reasonable size on tablets
  /// and desktop. Set it to `null` to let the bar fill the available width.
  final double? maxWidth;

  /// How much wider the lens gets while it is dragged (1.0 means no change).
  final double lensScale;

  /// How far the dragged lens sticks out above and below the bar, in logical
  /// pixels.
  final double lensOverflow;

  /// How much the icon under the dragged lens grows (1.0 means no change).
  final double lensIconScale;

  /// Whether labels are shown under the icons. [labelBehavior] then decides
  /// which tabs show one.
  final bool showLabels;

  /// The base text style for labels. Its color is replaced by [iconColor] or
  /// [activeIconColor].
  final TextStyle labelStyle;

  /// Which tabs show a label when [showLabels] is `true`.
  final NavLabelBehavior labelBehavior;

  /// Whether this style shows labels on at least one tab.
  bool get labelsEnabled =>
      showLabels && labelBehavior != NavLabelBehavior.never;

  /// Returns a copy of this style with the given fields replaced.
  ///
  /// To clear [maxWidth], pass `clearMaxWidth: true`.
  LiquidGlassNavStyle copyWith({
    double? blurSigma,
    Color? backgroundColor,
    Color? borderColor,
    Color? indicatorColor,
    Color? dragIndicatorColor,
    Color? lensHighlightColor,
    Color? iconColor,
    Color? activeIconColor,
    Color? badgeColor,
    Color? badgeTextColor,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    double? height,
    double? compactHeight,
    double? iconSize,
    double? compactIconSize,
    double? horizontalMargin,
    double? compactHorizontalMargin,
    double? bottomMargin,
    double? innerPadding,
    double? maxWidth,
    bool clearMaxWidth = false,
    double? lensScale,
    double? lensOverflow,
    double? lensIconScale,
    bool? showLabels,
    TextStyle? labelStyle,
    NavLabelBehavior? labelBehavior,
  }) {
    return LiquidGlassNavStyle(
      blurSigma: blurSigma ?? this.blurSigma,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      dragIndicatorColor: dragIndicatorColor ?? this.dragIndicatorColor,
      lensHighlightColor: lensHighlightColor ?? this.lensHighlightColor,
      iconColor: iconColor ?? this.iconColor,
      activeIconColor: activeIconColor ?? this.activeIconColor,
      badgeColor: badgeColor ?? this.badgeColor,
      badgeTextColor: badgeTextColor ?? this.badgeTextColor,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      height: height ?? this.height,
      compactHeight: compactHeight ?? this.compactHeight,
      iconSize: iconSize ?? this.iconSize,
      compactIconSize: compactIconSize ?? this.compactIconSize,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      compactHorizontalMargin:
          compactHorizontalMargin ?? this.compactHorizontalMargin,
      bottomMargin: bottomMargin ?? this.bottomMargin,
      innerPadding: innerPadding ?? this.innerPadding,
      maxWidth: clearMaxWidth ? null : (maxWidth ?? this.maxWidth),
      lensScale: lensScale ?? this.lensScale,
      lensOverflow: lensOverflow ?? this.lensOverflow,
      lensIconScale: lensIconScale ?? this.lensIconScale,
      showLabels: showLabels ?? this.showLabels,
      labelStyle: labelStyle ?? this.labelStyle,
      labelBehavior: labelBehavior ?? this.labelBehavior,
    );
  }

  /// Blends two styles, for example during an animated theme change.
  ///
  /// Booleans and enums switch over at `t == 0.5`.
  static LiquidGlassNavStyle lerp(
    LiquidGlassNavStyle a,
    LiquidGlassNavStyle b,
    double t,
  ) {
    if (identical(a, b)) return a;
    double d(double x, double y) => lerpDouble(x, y, t)!;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    final pickB = t >= 0.5;
    return LiquidGlassNavStyle(
      blurSigma: d(a.blurSigma, b.blurSigma),
      backgroundColor: c(a.backgroundColor, b.backgroundColor),
      borderColor: c(a.borderColor, b.borderColor),
      indicatorColor: c(a.indicatorColor, b.indicatorColor),
      dragIndicatorColor: c(a.dragIndicatorColor, b.dragIndicatorColor),
      lensHighlightColor: c(a.lensHighlightColor, b.lensHighlightColor),
      iconColor: c(a.iconColor, b.iconColor),
      activeIconColor: c(a.activeIconColor, b.activeIconColor),
      badgeColor: c(a.badgeColor, b.badgeColor),
      badgeTextColor: c(a.badgeTextColor, b.badgeTextColor),
      shadowColor: c(a.shadowColor, b.shadowColor),
      shadowBlurRadius: d(a.shadowBlurRadius, b.shadowBlurRadius),
      shadowOffset: Offset.lerp(a.shadowOffset, b.shadowOffset, t)!,
      height: d(a.height, b.height),
      compactHeight: d(a.compactHeight, b.compactHeight),
      iconSize: d(a.iconSize, b.iconSize),
      compactIconSize: d(a.compactIconSize, b.compactIconSize),
      horizontalMargin: d(a.horizontalMargin, b.horizontalMargin),
      compactHorizontalMargin:
          d(a.compactHorizontalMargin, b.compactHorizontalMargin),
      bottomMargin: d(a.bottomMargin, b.bottomMargin),
      innerPadding: d(a.innerPadding, b.innerPadding),
      maxWidth: (a.maxWidth == null || b.maxWidth == null)
          ? (pickB ? b.maxWidth : a.maxWidth)
          : d(a.maxWidth!, b.maxWidth!),
      lensScale: d(a.lensScale, b.lensScale),
      lensOverflow: d(a.lensOverflow, b.lensOverflow),
      lensIconScale: d(a.lensIconScale, b.lensIconScale),
      showLabels: pickB ? b.showLabels : a.showLabels,
      labelStyle: TextStyle.lerp(a.labelStyle, b.labelStyle, t)!,
      labelBehavior: pickB ? b.labelBehavior : a.labelBehavior,
    );
  }

  List<Object?> get _props => [
        blurSigma,
        backgroundColor,
        borderColor,
        indicatorColor,
        dragIndicatorColor,
        lensHighlightColor,
        iconColor,
        activeIconColor,
        badgeColor,
        badgeTextColor,
        shadowColor,
        shadowBlurRadius,
        shadowOffset,
        height,
        compactHeight,
        iconSize,
        compactIconSize,
        horizontalMargin,
        compactHorizontalMargin,
        bottomMargin,
        innerPadding,
        maxWidth,
        lensScale,
        lensOverflow,
        lensIconScale,
        showLabels,
        labelStyle,
        labelBehavior,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiquidGlassNavStyle && listEquals(other._props, _props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('blurSigma', blurSigma))
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(ColorProperty('indicatorColor', indicatorColor))
      ..add(DoubleProperty('height', height))
      ..add(DoubleProperty('compactHeight', compactHeight))
      ..add(FlagProperty('showLabels', value: showLabels, ifTrue: 'labels'))
      ..add(EnumProperty('labelBehavior', labelBehavior));
  }
}
