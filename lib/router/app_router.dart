import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/create_screen.dart';
import '../screens/folder_screen.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/prompt_detail_screen.dart';
import '../screens/recipe_runner_screen.dart';
import '../screens/saved_screen.dart';
import '../screens/settings_screen.dart';
import '../state/library_state.dart';
import '../widgets/root_shell.dart';

/// Path constants, so a typo is a compile error rather than a 404.
abstract final class Routes {
  static const home = '/';
  static const library = '/library';
  static const create = '/create';
  static const saved = '/saved';
  static const settings = '/settings';

  static String prompt(String variantId) => '/prompt/$variantId';

  /// A saved copy: the same prompt page, told which fork's edits to write to.
  static String savedCopy(String variantId, String folderId, String forkId) =>
      '/prompt/$variantId?folder=$folderId&fork=$forkId';

  static String recipe(String variantId) => '/prompt/$variantId/run';

  static String folder(String folderId) => '/folder/$folderId';

  static String libraryWith(LibraryFilter filter) => Uri(
    path: library,
    queryParameters: filter.toQueryParameters(),
  ).toString();
}

/// The five tabs live in a [StatefulShellRoute] so each keeps its own stack
/// and scroll position across tab switches — the behaviour the old
/// `IndexedStack` gave us, now with a URL per tab.
///
/// Detail pages (prompt, recipe, folder) are deliberately *not* branch
/// routes: they're pushed onto the root navigator so they cover the
/// navigation bar, which is how they behaved before routing.
///
/// URLs use go_router's default hash strategy (`/#/prompt/var_x`) rather
/// than path URLs. Hash links need no server-side rewrite rule, so a build
/// dropped on any static host keeps working; the prompt is still linkable,
/// which was the point.
GoRouter createRouter({String initialLocation = Routes.home}) {
  // Local rather than global so tests can build independent routers without
  // two live trees fighting over one GlobalKey.
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  // By default go_router leaves imperative pushes out of the address bar, on
  // the grounds that a pushed page isn't necessarily deep-linkable. Here it
  // always is — every pushed route resolves from its path alone — and a
  // prompt page whose URL you can't copy would defeat the point. `push` is
  // what keeps the back arrow and the Android back button working, so the
  // alternative (`go`) is worse.
  GoRouter.optionURLReflectsImperativeAPIs = true;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.library,
                builder: (context, state) => LibraryScreen(
                  initialFilter: LibraryFilter.fromQueryParameters(
                    state.uri.queryParameters,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.create,
                builder: (context, state) => const CreateScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.saved,
                builder: (context, state) => const SavedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/prompt/:variantId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return PromptDetailScreen(
            variantId: state.pathParameters['variantId']!,
            folderId: query['folder'],
            forkId: query['fork'],
          );
        },
        routes: [
          GoRoute(
            path: 'run',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => RecipeRunnerScreen(
              variantId: state.pathParameters['variantId']!,
              // Values come from the detail screen the user filled in. A
              // cold deep link has none, so the runner shows raw tokens.
              values: switch (state.extra) {
                final Map<String, String> values => values,
                _ => const {},
              },
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/folder/:folderId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            FolderScreen(folderId: state.pathParameters['folderId']!),
      ),
    ],
  );
}
