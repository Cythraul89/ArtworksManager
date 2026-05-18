import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Breakpoint below which the mobile bottom nav is shown.
const _mobileBreakpoint = 600.0;

class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= _mobileBreakpoint
        ? _DesktopShell(navigationShell: navigationShell)
        : _MobileShell(navigationShell: navigationShell);
  }

  static void _go(StatefulNavigationShell shell, int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  static const _destinations = [
    (icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard'),
    (icon: Icons.photo_library_outlined, label: 'Collection', route: '/collection'),
    (icon: Icons.settings_outlined, label: 'Settings', route: '/settings'),
  ];
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => AdaptiveShell._go(navigationShell, i),
        destinations: AdaptiveShell._destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final extended = MediaQuery.sizeOf(context).width >= 1200;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => AdaptiveShell._go(navigationShell, i),
            destinations: AdaptiveShell._destinations
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
