import 'package:flutter/material.dart';
import 'package:liquid_glass_floating_tab_bar/liquid_glass_floating_tab_bar.dart';

void main() => runApp(const LiquidGlassExampleApp());

const _avatarUrl = 'https://i.pravatar.cc/150?img=12';

/// Live settings for the demo, edited on the Profile tab.
class DemoSettings {
  const DemoSettings({
    this.dark = true,
    this.rtl = false,
    this.showLabels = false,
    this.labelBehavior = NavLabelBehavior.always,
    this.shrinkMode = ShrinkMode.threshold,
    this.enableShrink = true,
    this.enableDrag = true,
    this.enableHaptics = true,
  });

  final bool dark;
  final bool rtl;
  final bool showLabels;
  final NavLabelBehavior labelBehavior;
  final ShrinkMode shrinkMode;
  final bool enableShrink;
  final bool enableDrag;
  final bool enableHaptics;

  DemoSettings copyWith({
    bool? dark,
    bool? rtl,
    bool? showLabels,
    NavLabelBehavior? labelBehavior,
    ShrinkMode? shrinkMode,
    bool? enableShrink,
    bool? enableDrag,
    bool? enableHaptics,
  }) =>
      DemoSettings(
        dark: dark ?? this.dark,
        rtl: rtl ?? this.rtl,
        showLabels: showLabels ?? this.showLabels,
        labelBehavior: labelBehavior ?? this.labelBehavior,
        shrinkMode: shrinkMode ?? this.shrinkMode,
        enableShrink: enableShrink ?? this.enableShrink,
        enableDrag: enableDrag ?? this.enableDrag,
        enableHaptics: enableHaptics ?? this.enableHaptics,
      );
}

class LiquidGlassExampleApp extends StatefulWidget {
  const LiquidGlassExampleApp({super.key});

  @override
  State<LiquidGlassExampleApp> createState() => _LiquidGlassExampleAppState();
}

class _LiquidGlassExampleAppState extends State<LiquidGlassExampleApp> {
  DemoSettings _settings = const DemoSettings();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Glass Nav Bar',
      debugShowCheckedModeBanner: false,
      themeMode: _settings.dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorSchemeSeed: Colors.pink,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFF0C1014),
      ),
      builder: (context, child) => Directionality(
        textDirection: _settings.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      home: HomeShell(
        settings: _settings,
        onSettingsChanged: (s) => setState(() => _settings = s),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final DemoSettings settings;
  final ValueChanged<DemoSettings> onSettingsChanged;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _navController = LiquidGlassNavBarController();
  final _scrollControllers = List.generate(5, (_) => ScrollController());
  int _index = 0;
  int _unreadMessages = 4;

  @override
  void dispose() {
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _index) {
      // Tapping the selected tab again scrolls its page back to the top.
      final controller = _scrollControllers[index];
      if (controller.hasClients) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    setState(() {
      _index = index;
      if (index == 2) _unreadMessages = 0;
    });
    _navController.expand();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final base = s.dark
        ? const LiquidGlassNavStyle.dark()
        : const LiquidGlassNavStyle.light();
    final style = base.copyWith(
      showLabels: s.showLabels,
      labelBehavior: s.labelBehavior,
      height: s.showLabels ? 68 : 64,
    );

    final pages = <Widget>[
      FeedPage(controller: _scrollControllers[0]),
      ReelsPage(controller: _scrollControllers[1]),
      MessagesPage(controller: _scrollControllers[2]),
      SearchPage(controller: _scrollControllers[3]),
      ProfilePage(
        controller: _scrollControllers[4],
        settings: s,
        onChanged: widget.onSettingsChanged,
      ),
    ];

    return Scaffold(
      // The body runs behind the bar, so the glass has something to blur.
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _navController.handleScrollNotification,
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: LiquidGlassNavBar(
        controller: _navController,
        currentIndex: _index,
        onTap: _onTap,
        style: style,
        shrinkMode: s.shrinkMode,
        enableShrinkOnScroll: s.enableShrink,
        enableDragToSwitch: s.enableDrag,
        enableHaptics: s.enableHaptics,
        items: [
          const LiquidGlassNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          const LiquidGlassNavItem(
            icon: Icons.smart_display_outlined,
            activeIcon: Icons.smart_display,
            label: 'Reels',
          ),
          LiquidGlassNavItem(
            icon: Icons.send_outlined,
            activeIcon: Icons.send_rounded,
            label: 'Messages',
            badge: _unreadMessages > 0
                ? NavBadge.count(_unreadMessages)
                : const NavBadge.dot(position: NavBadgePosition.bottomEnd),
          ),
          const LiquidGlassNavItem(
            icon: Icons.search_rounded,
            activeIcon: Icons.manage_search_rounded,
            label: 'Search',
          ),
          LiquidGlassNavItem.custom(
            label: 'Profile',
            badge: const NavBadge.dot(position: NavBadgePosition.bottomEnd),
            child: const _Avatar(),
            activeChild: _Avatar(
              ringColor: s.dark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.ringColor});

  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      backgroundColor: Colors.pink.shade200,
      backgroundImage: const NetworkImage(_avatarUrl),
      onBackgroundImageError: (_, _) {},
    );
    if (ringColor == null) return avatar;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor!, width: 1.5),
      ),
      child: Padding(padding: const EdgeInsets.all(1.5), child: avatar),
    );
  }
}

// -----------------------------------------------------------------------------
// Pages

/// Extra space at the bottom of each page, so the last items can scroll
/// clear of the floating bar.
double _bottomGap(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + 24;

class FeedPage extends StatelessWidget {
  const FeedPage({super.key, required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        const SliverAppBar(
          floating: true,
          title: Text('Liquid Glass', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        SliverList.builder(
          itemCount: 30,
          itemBuilder: (context, i) => _Post(index: i),
        ),
        SliverToBoxAdapter(child: SizedBox(height: _bottomGap(context))),
      ],
    );
  }
}

class _Post extends StatelessWidget {
  const _Post({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: _seedColor(index),
            backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=${index % 70}'),
            onBackgroundImageError: (_, _) {},
          ),
          title: Text('user_$index', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Sponsored'),
          trailing: const Icon(Icons.more_horiz),
        ),
        AspectRatio(aspectRatio: 1, child: DemoImage(seed: 'post$index')),
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Row(
            children: [
              Icon(Icons.favorite_border),
              SizedBox(width: 16),
              Icon(Icons.mode_comment_outlined),
              SizedBox(width: 16),
              Icon(Icons.send_outlined),
              Spacer(),
              Icon(Icons.bookmark_border),
            ],
          ),
        ),
      ],
    );
  }
}

class ReelsPage extends StatelessWidget {
  const ReelsPage({super.key, required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.only(bottom: _bottomGap(context)),
      itemCount: 20,
      itemBuilder: (context, i) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DemoImage(seed: 'reel$i', width: 600, height: 1000),
            PositionedDirectional(
              start: 16,
              bottom: 120,
              child: Text(
                'Reel #$i',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(blurRadius: 8)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key, required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        const SliverAppBar(floating: true, title: Text('Messages')),
        SliverList.builder(
          itemCount: 40,
          itemBuilder: (context, i) => ListTile(
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: _seedColor(i + 7),
              backgroundImage: NetworkImage('https://i.pravatar.cc/120?img=${(i + 20) % 70}'),
              onBackgroundImageError: (_, _) {},
            ),
            title: Text('Friend $i'),
            subtitle: Text(i.isEven ? '${i % 5 + 1} new messages · 3d' : 'Sent a reel · 1w'),
            trailing: i.isEven
                ? const Icon(Icons.circle, size: 10, color: Colors.blueAccent)
                : null,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: _bottomGap(context))),
      ],
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key, required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        bottom: _bottomGap(context),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 0.75,
      ),
      itemCount: 90,
      itemBuilder: (context, i) => DemoImage(seed: 'grid$i', width: 300, height: 400),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.controller,
    required this.settings,
    required this.onChanged,
  });

  final ScrollController controller;
  final DemoSettings settings;
  final ValueChanged<DemoSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return ListView(
      controller: controller,
      padding: EdgeInsets.only(bottom: _bottomGap(context)),
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top + 24),
        const Center(child: SizedBox.square(dimension: 96, child: _Avatar())),
        const SizedBox(height: 12),
        const Center(
          child: Text('Nav bar playground', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Dark style'),
          value: s.dark,
          onChanged: (v) => onChanged(s.copyWith(dark: v)),
        ),
        SwitchListTile(
          title: const Text('Right-to-left'),
          value: s.rtl,
          onChanged: (v) => onChanged(s.copyWith(rtl: v)),
        ),
        SwitchListTile(
          title: const Text('Show labels'),
          value: s.showLabels,
          onChanged: (v) => onChanged(s.copyWith(showLabels: v)),
        ),
        ListTile(
          title: const Text('Label behavior'),
          enabled: s.showLabels,
          trailing: DropdownButton<NavLabelBehavior>(
            value: s.labelBehavior,
            onChanged: s.showLabels
                ? (v) => onChanged(s.copyWith(labelBehavior: v))
                : null,
            items: [
              for (final b in NavLabelBehavior.values)
                DropdownMenuItem(value: b, child: Text(b.name)),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Shrink on scroll'),
          value: s.enableShrink,
          onChanged: (v) => onChanged(s.copyWith(enableShrink: v)),
        ),
        ListTile(
          title: const Text('Shrink mode'),
          enabled: s.enableShrink,
          trailing: SegmentedButton<ShrinkMode>(
            segments: const [
              ButtonSegment(value: ShrinkMode.threshold, label: Text('Snap')),
              ButtonSegment(value: ShrinkMode.continuous, label: Text('Follow')),
            ],
            selected: {s.shrinkMode},
            onSelectionChanged: s.enableShrink
                ? (v) => onChanged(s.copyWith(shrinkMode: v.single))
                : null,
          ),
        ),
        SwitchListTile(
          title: const Text('Drag between tabs'),
          value: s.enableDrag,
          onChanged: (v) => onChanged(s.copyWith(enableDrag: v)),
        ),
        SwitchListTile(
          title: const Text('Haptics'),
          value: s.enableHaptics,
          onChanged: (v) => onChanged(s.copyWith(enableHaptics: v)),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Scroll down to see the bar shrink. Press and drag across it to move the lens.'),
        ),
        // Images under the settings, so there is something to scroll and blur.
        for (var i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(aspectRatio: 16 / 9, child: DemoImage(seed: 'profile$i', width: 800, height: 450)),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Images

Color _seedColor(int i) => HSLColor.fromAHSL(1, (i * 47) % 360.0, 0.65, 0.55).toColor();

/// A network photo that falls back to a colorful gradient, so the blur
/// still has something to show when there's no internet.
class DemoImage extends StatelessWidget {
  const DemoImage({super.key, required this.seed, this.width = 800, this.height = 800});

  final String seed;
  final int width;
  final int height;

  @override
  Widget build(BuildContext context) {
    final hash = seed.hashCode;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_seedColor(hash), _seedColor(hash ~/ 7 + 3)],
        ),
      ),
    );
    return Image.network(
      'https://picsum.photos/seed/$seed/$width/$height',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      frameBuilder: (context, child, frame, wasSync) => Stack(
        fit: StackFit.expand,
        children: [
          fallback,
          AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: child,
          ),
        ],
      ),
    );
  }
}
