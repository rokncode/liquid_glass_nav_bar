/// What a [ScrollShrinkTracker] decided after a scroll delta.
enum ShrinkDirective {
  /// Keep the bar as it is.
  none,

  /// Animate the bar to compact.
  shrink,

  /// Animate the bar to full size.
  expand,
}

/// Turns raw scroll deltas into shrink and expand decisions.
///
/// Deltas are added up while they keep going the same way. The tracker only
/// acts once the total passes [threshold], so small back-and-forth jitter
/// (a finger resting on the screen, or a list settling) never toggles the
/// bar.
class ScrollShrinkTracker {
  /// Creates a tracker that acts after [threshold] pixels of scrolling the
  /// same way.
  ScrollShrinkTracker({this.threshold = 10}) : assert(threshold >= 0);

  /// How many pixels of scrolling the same way it takes to act.
  double threshold;

  double _accumulated = 0;

  /// The scrolling added up so far in the current direction.
  double get accumulated => _accumulated;

  /// Adds [delta] and returns what the bar should do.
  ///
  /// A positive [delta] means the content moved up (the user is scrolling
  /// down, toward the end of the list).
  ShrinkDirective addDelta(double delta) {
    if (delta == 0) return ShrinkDirective.none;
    if (_accumulated != 0 && _accumulated.sign != delta.sign) {
      _accumulated = 0;
    }
    _accumulated += delta;
    if (_accumulated > threshold) {
      _accumulated = 0;
      return ShrinkDirective.shrink;
    }
    if (_accumulated < -threshold) {
      _accumulated = 0;
      return ShrinkDirective.expand;
    }
    return ShrinkDirective.none;
  }

  /// Clears the running total.
  void reset() => _accumulated = 0;
}
