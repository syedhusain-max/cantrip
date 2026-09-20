import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';

/// The app's root navigation shell: a bottom [NavigationBar] on narrow
/// (phone) layouts and a side [NavigationRail] on wide (tablet/desktop)
/// layouts, both driving the same five tabs.
///
/// The tabs themselves are branches of the router's [StatefulShellRoute],
/// so each keeps its own navigation stack and every tab has a URL.
class RootShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RootShell({super.key, required this.navigationShell});

  static const _wideBreakpoint = 840.0;

  /// Re-tapping the current tab pops it back to its root, which is what a
  /// bottom bar is expected to do.
  void _select(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  static const List<({IconData icon, IconData selectedIcon, String labelKey})>
  _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, labelKey: 'nav.home'),
    (
      icon: Icons.auto_stories_outlined,
      selectedIcon: Icons.auto_stories,
      labelKey: 'nav.library',
    ),
    (
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
      labelKey: 'nav.create',
    ),
    (
      icon: Icons.bookmark_outline,
      selectedIcon: Icons.bookmark,
      labelKey: 'nav.saved',
    ),
    (
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      labelKey: 'nav.settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final index = navigationShell.currentIndex;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Icon(Icons.auto_awesome, size: 28),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(strings.t(d.labelKey)),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _select,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: strings.t(d.labelKey),
            ),
        ],
      ),
    );
  }
}
