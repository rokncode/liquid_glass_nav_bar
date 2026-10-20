import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'nav_style.dart';

/// The frosted capsule behind the tabs: the shadow, the blurred backdrop
/// with its tint, and the edge highlight.
///
/// The blur sits in its own [RepaintBoundary] and [ClipRRect], so the
/// indicator and icons above it can repaint without re-recording the
/// backdrop filter.
class GlassSurface extends StatelessWidget {
  /// Creates the glass surface for [style].
  const GlassSurface({super.key, required this.style});

  /// The style that sets the blur, tint, border, and shadow.
  final LiquidGlassNavStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = Radius.circular(constraints.maxHeight / 2);
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              child: CustomPaint(
                painter: _OuterShadowPainter(
                  radius: radius,
                  color: style.shadowColor,
                  blurRadius: style.shadowBlurRadius,
                  offset: style.shadowOffset,
                ),
              ),
            ),
            RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.all(radius),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: style.blurSigma,
                    sigmaY: style.blurSigma,
                    tileMode: TileMode.mirror,
                  ),
                  child: ColoredBox(color: style.backgroundColor),
                ),
              ),
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: _GlassEdgePainter(
                  radius: radius,
                  borderColor: style.borderColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Paints a drop shadow only outside the capsule.
///
/// A plain `BoxShadow` would also be painted under the translucent glass,
/// where the blur would pick it up and make the bar look dirty, which shows
/// most on light backgrounds.
class _OuterShadowPainter extends CustomPainter {
  _OuterShadowPainter({
    required this.radius,
    required this.color,
    required this.blurRadius,
    required this.offset,
  });

  final Radius radius;
  final Color color;
  final double blurRadius;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0 || size.isEmpty) return;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, radius);
    final reach = blurRadius * 2 + offset.distance;
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(reach))
      ..addRRect(rrect);
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRRect(
        rrect.shift(offset),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            Shadow.convertRadiusToSigma(blurRadius),
          ),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter old) =>
      old.radius != radius ||
      old.color != color ||
      old.blurRadius != blurRadius ||
      old.offset != offset;
}

/// Paints the glass edge: a 1px stroke that is bright at the top and fades
/// toward the bottom, plus a faint sheen across the top half.
class _GlassEdgePainter extends CustomPainter {
  _GlassEdgePainter({required this.radius, required this.borderColor});

  final Radius radius;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final alpha = borderColor.a;

    // The sheen is the top half going from slightly lighter to clear, like
    // light caught on curved glass.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            borderColor.withValues(alpha: alpha * 0.22),
            borderColor.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            borderColor,
            borderColor.withValues(alpha: alpha * 0.45),
            borderColor.withValues(alpha: alpha * 0.25),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassEdgePainter old) =>
      old.radius != radius || old.borderColor != borderColor;
}
