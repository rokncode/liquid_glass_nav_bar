import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_nav_bar/liquid_glass_nav_bar.dart';
import 'package:liquid_glass_nav_bar/src/geometry.dart';
import 'package:liquid_glass_nav_bar/src/scroll_shrink.dart';

void main() {
  group('NavBarGeometry', () {
    const ltr = NavBarGeometry(width: 512, itemCount: 5, padding: 6, isRtl: false);
    const rtl = NavBarGeometry(width: 512, itemCount: 5, padding: 6, isRtl: true);

    test('slot centers', () {
      expect(ltr.slotWidth, 100);
      expect(ltr.centerXFor(0), 56);
      expect(ltr.centerXFor(4), 456);
      expect(rtl.centerXFor(0), 456);
      expect(rtl.centerXFor(4), 56);
    });

    test('dx to index round-trips in both directions', () {
      for (var i = 0; i < 5; i++) {
        expect(ltr.indexFromDx(ltr.centerXFor(i.toDouble())), i);
        expect(rtl.indexFromDx(rtl.centerXFor(i.toDouble())), i);
      }
      expect(ltr.logicalFromDx(106), closeTo(0.5, 1e-9));
      expect(ltr.indexFromDx(-50), 0);
      expect(ltr.indexFromDx(5000), 4);
    });

    test('velocity flips in RTL', () {
      expect(ltr.logicalVelocity(200), 2);
      expect(rtl.logicalVelocity(200), -2);
    });

    test('rubber band keeps positions near the ends', () {
      expect(ltr.rubberBand(2.3), 2.3);
      expect(ltr.rubberBand(-10), closeTo(-0.3, 1e-3));
      expect(ltr.rubberBand(14), closeTo(4.3, 1e-3));
      expect(ltr.rubberBand(-0.01), closeTo(-0.01, 1e-3));
    });
  });

  group('ScrollShrinkTracker', () {
    test('acts once the threshold is crossed in one direction', () {
      final tracker = ScrollShrinkTracker(threshold: 10);
      expect(tracker.addDelta(4), ShrinkDirective.none);
      expect(tracker.addDelta(4), ShrinkDirective.none);
      expect(tracker.addDelta(4), ShrinkDirective.shrink);
      expect(tracker.addDelta(-6), ShrinkDirective.none);
      expect(tracker.addDelta(-6), ShrinkDirective.expand);
    });

    test('changing direction resets the total', () {
      final tracker = ScrollShrinkTracker(threshold: 10);
      tracker.addDelta(9);
      tracker.addDelta(-1);
      expect(tracker.accumulated, -1);
      expect(tracker.addDelta(9), ShrinkDirective.none);
    });
  });

  group('LiquidGlassNavStyle', () {
    test('copyWith replaces only the given fields', () {
      const base = LiquidGlassNavStyle.dark();
      final copy = base.copyWith(blurSigma: 30, showLabels: true);
      expect(copy.blurSigma, 30);
      expect(copy.showLabels, isTrue);
      expect(copy.height, base.height);
      expect(copy.copyWith(blurSigma: 20, showLabels: false), base);
      expect(base.copyWith(clearMaxWidth: true).maxWidth, isNull);
    });

    test('equality and hashCode', () {
      expect(const LiquidGlassNavStyle(), const LiquidGlassNavStyle.dark());
      expect(
        const LiquidGlassNavStyle().hashCode,
        const LiquidGlassNavStyle.dark().hashCode,
      );
      expect(
        const LiquidGlassNavStyle.light(),
        isNot(const LiquidGlassNavStyle.dark()),
      );
    });

    test('lerp hits both ends', () {
      const a = LiquidGlassNavStyle.light();
      const b = LiquidGlassNavStyle.dark();
      expect(LiquidGlassNavStyle.lerp(a, b, 0), a);
      expect(LiquidGlassNavStyle.lerp(a, b, 1), b);
      expect(
        LiquidGlassNavStyle.lerp(a, b.copyWith(height: 80), 0.5).height,
        72,
      );
    });

    test('labelsEnabled', () {
      const s = LiquidGlassNavStyle();
      expect(s.labelsEnabled, isFalse);
      expect(s.copyWith(showLabels: true).labelsEnabled, isTrue);
      expect(
        s
            .copyWith(showLabels: true, labelBehavior: NavLabelBehavior.never)
            .labelsEnabled,
        isFalse,
      );
    });
  });

  group('NavBadge', () {
    test('labels', () {
      expect(const NavBadge.dot().label, isNull);
      expect(const NavBadge.dot().isDot, isTrue);
      expect(const NavBadge.count(7).label, '7');
      expect(const NavBadge.count(100).label, '99+');
      expect(const NavBadge.count(1000, maxCount: 999).label, '999+');
      expect(const NavBadge.text('NEW').label, 'NEW');
      expect(const NavBadge.count(0).isVisible, isFalse);
      expect(const NavBadge.count(3), const NavBadge.count(3));
      expect(
        const NavBadge.dot(color: Colors.blue),
        isNot(const NavBadge.dot()),
      );
    });
  });
}
