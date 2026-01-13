import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/pack/pack_gate_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/settings/settings_screen.dart';

/// App router provider with offline pack MVP routes.
///
/// Routes:
/// - `/` - PackGateScreen (first launch, pack check)
/// - `/library` - LibraryScreen (manifest-driven navigation)
/// - `/reader` - ReaderScreen (local HTML viewer)
/// - `/settings` - SettingsScreen (update/delete pack)
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // First screen: check if pack exists
      GoRoute(
        path: '/',
        name: 'gate',
        builder: (context, state) => const PackGateScreen(),
      ),

      // Library: manifest-driven navigation tree
      GoRoute(
        path: '/library',
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),

      // Reader: local HTML viewer
      GoRoute(
        path: '/reader',
        name: 'reader',
        builder: (context, state) => const ReaderScreen(),
      ),

      // Settings: pack management
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
