import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'state/auth_controller.dart';
import 'state/backend_config.dart';
import 'state/library_state.dart';
import 'state/remote_user_data_api.dart';
import 'state/supabase_auth_api.dart';
import 'state/synced_user_data_store.dart';
import 'state/user_data_store.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final local = LocalUserDataStore();
  final backend = await _connectBackend();
  final store = backend == null
      ? local
      : SyncedUserDataStore(
          local: local,
          remote: SupabaseUserDataApi(backend),
          onError: (error) => debugPrint('PromptCraft sync: $error'),
        );

  final library = LibraryState(store: store);
  final theme = ThemeController();

  final auth = AuthController(
    api: backend == null ? null : SupabaseAuthApi(backend),
    // Signing in changes what the store returns, so the library re-reads.
    onSignedIn: library.load,
    // Signing out wipes the device copy, then re-reads into an empty state.
    // The data is safe on the server; leaving it here would hand one
    // account's folders to whoever signs in next, because the first-sign-in
    // merge would upload them into the new account.
    onSignedOut: () async {
      await local.clear();
      await library.load();
    },
  );

  // Load saved data in the background rather than blocking first paint.
  // Both controllers notify when they finish, so the UI fills in a frame
  // later instead of showing a splash for the sake of local storage.
  library.load();
  theme.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: library),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: const PromptCraftApp(),
    ),
  );
}

/// Returns a live Supabase client, or null to run the app local-only — the
/// state it was in before the backend existed.
///
/// Null happens two ways: no keys were defined at build time, or
/// initialisation failed (no network on a cold start, a bad key). Both land
/// in the same place deliberately. The app opens and works either way; it
/// just doesn't sync, and Settings hides the account section.
Future<SupabaseClient?> _connectBackend() async {
  if (!BackendConfig.isConfigured) return null;
  try {
    await Supabase.initialize(
      url: BackendConfig.url,
      publishableKey: BackendConfig.publishableKey,
    );
    return Supabase.instance.client;
  } catch (error) {
    debugPrint('PromptCraft: Supabase unavailable, staying local ($error)');
    return null;
  }
}
