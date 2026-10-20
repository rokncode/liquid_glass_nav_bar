## 0.1.0

* First release.
* A floating frosted-glass capsule with a gradient edge highlight and an outer-only shadow.
* A selected-tab indicator that springs to tapped tabs.
* Drag across the bar to move a lens indicator. It follows the finger, stretches with speed, and snaps to the nearest tab on release, with selection-click haptics as it crosses tabs.
* Shrink on scroll, in `threshold` or `continuous` mode, from a `ScrollController` or from `LiquidGlassNavBarController.handleScrollNotification`.
* Dot, count, and text badges, and custom widget tabs (for example an avatar).
* `LiquidGlassNavStyle.light()` and `.dark()` with `copyWith` and `lerp`.
* RTL support, and a semantic button with selected state for each tab.
