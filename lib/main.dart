import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'state/backend_config.dart';
import 'state/library_state.dart';
import 'state/remote_user_data_api.dart';
import 'state/synced_user_data_store.dart';
import 'state/user_data_store.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final local = LocalUserDataStore();
  final store = await _buildStore(local);

  final library = LibraryState(store: store);
  final theme = ThemeController();

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
      ],
      child: const PromptCraftApp(),
    ),
  );
}

/// With no Supabase keys defined the app is local-only — the state it was in
/// before the backend existed. If initialising Supabase fails (no network on
/// a cold start, a bad key), we fall back to the same place rather than
/// refusing to open.
Future<UserDataStore> _buildStore(LocalUserDataStore local) async {
  if (!BackendConfig.isConfigured) return local;
  try {
    await Supabase.initialize(
      url: BackendConfig.url,
      publishableKey: BackendConfig.publishableKey,
    );
    return SyncedUserDataStore(
      local: local,
      remote: SupabaseUserDataApi(Supabase.instance.client),
      onError: (error) => debugPrint('PromptCraft sync: $error'),
    );
  } catch (error) {
    debugPrint('PromptCraft: Supabase unavailable, staying local ($error)');
    return local;
  }
}
