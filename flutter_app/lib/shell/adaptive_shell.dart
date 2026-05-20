import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/services/nextcloud_service.dart';
import '../core/services/remote_backup_check.dart';

/// Breakpoint below which the mobile bottom nav is shown.
const _mobileBreakpoint = 600.0;

const _destinations = [
  (icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard'),
  (icon: Icons.photo_library_outlined, label: 'Collection', route: '/collection'),
  (icon: Icons.settings_outlined, label: 'Settings', route: '/settings'),
];

void _go(StatefulNavigationShell shell, int index) {
  shell.goBranch(index, initialLocation: index == shell.currentIndex);
}

class AdaptiveShell extends ConsumerStatefulWidget {
  const AdaptiveShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends ConsumerState<AdaptiveShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkForNewBackup(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BackupInfo?>(pendingRestoreProvider, (_, backup) {
      if (backup != null) {
        ref.read(pendingRestoreProvider.notifier).state = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showPendingRestoreDialog(context, backup);
        });
      }
    });

    final width = MediaQuery.sizeOf(context).width;
    return width >= _mobileBreakpoint
        ? _DesktopShell(navigationShell: widget.navigationShell)
        : _MobileShell(navigationShell: widget.navigationShell);
  }

  void _showPendingRestoreDialog(BuildContext context, BackupInfo backup) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('New backup available'),
        content: Text(
          'A Nextcloud backup from '
          '${DateFormat('dd MMM yyyy').format(backup.backupDate)} '
          'is newer than your last local sync.\n\n'
          'Open Nextcloud settings to restore it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.go('/settings/nextcloud');
            },
            child: const Text('Open Nextcloud settings'),
          ),
        ],
      ),
    );
  }
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
        onDestinationSelected: (i) => _go(navigationShell, i),
        destinations: _destinations
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
            onDestinationSelected: (i) => _go(navigationShell, i),
            destinations: _destinations
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
