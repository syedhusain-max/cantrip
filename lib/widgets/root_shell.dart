import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../screens/create_screen.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/saved_screen.dart';
import '../screens/settings_screen.dart';
import 'root_shell_scope.dart';

/// The app's root navigation shell: a bottom [NavigationBar] on narrow
/// (phone) layouts and a side [NavigationRail] on wide (tablet/desktop)
/// layouts, both driving the same five tabs.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  static const _wideBreakpoint = 840.0;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  late final _tabs = [
    const HomeScreen(),
    const LibraryScreen(),
    const CreateScreen(),
    const SavedScreen(),
    const SettingsScreen(),
  ];

  List<({IconData icon, IconData selectedIcon, String labelKey})>
  get _destinations => const [
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
    final isWide =
        MediaQuery.sizeOf(context).width >= RootShell._wideBreakpoint;
    final body = RootShellScope(
      goToCreate: () => setState(() => _index = 2),
      child: IndexedStack(index: _index, children: _tabs),
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
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
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
