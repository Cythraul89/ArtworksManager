import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'shell/adaptive_shell.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/collection/collection_screen.dart';
import 'features/detail/detail_screen.dart';
import 'features/addedit/addedit_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/logs_screen.dart';
import 'features/nextcloud/nextcloud_screen.dart';

final _router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AdaptiveShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/collection',
            builder: (_, __) => const CollectionScreen(),
            routes: [
              GoRoute(
                path: 'artwork/:id',
                builder: (_, state) =>
                    DetailScreen(artworkId: int.parse(state.pathParameters['id']!)),
              ),
              GoRoute(
                path: 'add',
                builder: (_, __) => const AddEditScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (_, state) =>
                    AddEditScreen(artworkId: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'nextcloud',
                builder: (_, __) => const NextcloudScreen(),
              ),
              GoRoute(
                path: 'logs',
                builder: (_, __) => const LogsScreen(),
              ),
            ],
          ),
        ]),
      ],
    ),
  ],
);

class ArtworksManagerApp extends StatelessWidget {
  const ArtworksManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Artworks Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C6BC0)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C6BC0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
