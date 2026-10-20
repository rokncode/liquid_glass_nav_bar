import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'geometry.dart';
import 'nav_style.dart';

/// Paints the selected-tab capsule and, while it is dragged, the glass lens
/// it turns into.
///
/// It reads live values through getters and repaints from [repaint], so a
/// moving indicator never rebuilds any widgets.
class IndicatorPainter extends CustomPainter {
  /// Creates the indicator painter.
  IndicatorPainter({
    required this.geometry,
    required this.style,
    required this.position,
    required this.press,
    required this.stretch,
    required Listenable repaint,
  }) : super(repaint: repaint);

  /// Maps tab positions to pixels.
  final NavBarGeometry geometry;

  /// The colors and lens sizes.
  final LiquidGlassNavStyle style;

  /// The current logical tab position of the indicator.
  final ValueGetter<double> position;

  /// How far the indicator has turned into a lens: 0 is at rest, 1 is fully
  /// pressed. It can go a little past 1 when the pop overshoots.
  final ValueGetter<double> press;

  /// The squash-and-stretch amount from 0 to 1, driven by speed.
  final ValueGetter<double> stretch;

  /// The indicator's rectangle for the current values. Exposed for tests.
  Rect indicatorRect(Size size) {
    final p = press();
    final s = stretch();
    final inset = style.innerPadding;
    final restWidth = geometry.slotWidth;
    final restHeight = (size.height - 2 * inset).clamp(0.0, double.infinity);

    var width = lerpDouble(restWidth, restWidth * style.lensScale, p)!;
    var height =
        lerpDouble(restHeight, size.height + 2 * style.lensOverflow, p)!;

    // Squash and stretch: speed makes it wider and slightly flatter, so the
    // area looks roughly the same.
    width *= 1 + 0.32 * s;
    height *= 1 - 0.10 * s;

    return Rect.fromCenter(
      center: Offset(geometry.centerXFor(position()), size.height / 2),
      width: width,
      height: height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || geometry.slotWidth <= 0) return;
    final p = press().clamp(0.0, 1.2);
    final rect = indicatorRect(size);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));
    final lensT = p.clamp(0.0, 1.0);

    // A faint shadow under the lens helps it read as lifted off the bar.
    if (lensT > 0) {
      canvas.drawRRect(
        rrect.shift(const Offset(0, 3)),
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, 0.18 * lensT)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    canvas.drawRRect(
      rrect,
      Paint()
        ..color =
            Color.lerp(style.indicatorColor, style.dragIndicatorColor, lensT)!,
    );

    if (lensT == 0) return;

    final highlight = style.lensHighlightColor;
    final a = highlight.a * lensT;

    // Specular highlight: light caught along the top curve of the lens.
    final sheenRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height * 0.55,
    );
    canvas
      ..save()
      ..clipRRect(rrect)
      ..drawRRect(
        RRect.fromRectAndRadius(
          sheenRect.deflate(rect.height * 0.08),
          Radius.circular(rect.height / 2),
        ),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              highlight.withValues(alpha: a * 0.35),
              highlight.withValues(alpha: 0),
            ],
          ).createShader(sheenRect),
      )
      ..restore();

    // The rim: bright at the top-left and bottom-right, like light bending
    // around the edge of a thick piece of glass.
    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            highlight.withValues(alpha: a),
            highlight.withValues(alpha: a * 0.15),
            highlight.withValues(alpha: a * 0.15),
            highlight.withValues(alpha: a * 0.7),
          ],
          stops: const [0, 0.35, 0.65, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(IndicatorPainter old) =>
      old.geometry != geometry || old.style != style;
}
