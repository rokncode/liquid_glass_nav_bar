import 'package:flutter/widgets.dart';

/// The interface a nav bar state implements so a
/// [LiquidGlassNavBarController] can drive it.
///
/// This is not part of the public API.
abstract interface class LiquidGlassNavBarDelegate {
  /// Whether the bar is compact, or animating toward compact.
  bool get isCompact;

  /// Animates the bar to full size.
  void expand();

  /// Animates the bar to its compact size.
  void shrink();

  /// Handles a scroll notification from a scrollable below the bar.
  void handleScrollNotification(ScrollNotification notification);
}

/// Lets you expand or shrink a `LiquidGlassNavBar` yourself, and feed it
/// scroll events without passing a `ScrollController`.
///
/// This is useful when each tab has its own scroll view. Wrap the body once
/// in a [NotificationListener] instead of handing a controller to every list:
///
/// ```dart
/// final navController = LiquidGlassNavBarController();
///
/// Scaffold(
///   extendBody: true,
///   body: NotificationListener<ScrollNotification>(
///     onNotification: navController.handleScrollNotification,
///     child: pages[index],
///   ),
///   bottomNavigationBar: LiquidGlassNavBar(
///     controller: navController,
///     // ...
///   ),
/// )
/// ```
class LiquidGlassNavBarController {
  LiquidGlassNavBarDelegate? _delegate;

  /// Whether the controller is attached to a nav bar.
  bool get isAttached => _delegate != null;

  /// Whether the bar is compact, or animating toward compact. Returns false
  /// when the controller isn't attached.
  bool get isCompact => _delegate?.isCompact ?? false;

  /// Animates the bar to full size.
  void expand() => _delegate?.expand();

  /// Animates the bar to its compact size.
  void shrink() => _delegate?.shrink();

  /// Passes [notification] to the bar so it can shrink or expand.
  ///
  /// Always returns `false`, so the notification keeps bubbling up. That
  /// means you can pass this method directly as a
  /// `NotificationListener.onNotification` callback.
  bool handleScrollNotification(ScrollNotification notification) {
    _delegate?.handleScrollNotification(notification);
    return false;
  }

  /// Connects the controller to a nav bar. Called by the nav bar.
  void attach(LiquidGlassNavBarDelegate delegate) {
    assert(
      _delegate == null || identical(_delegate, delegate),
      'A LiquidGlassNavBarController can only be attached to one nav bar.',
    );
    _delegate = delegate;
  }

  /// Disconnects the controller from [delegate]. Called by the nav bar.
  void detach(LiquidGlassNavBarDelegate delegate) {
    if (identical(_delegate, delegate)) _delegate = null;
  }
}
