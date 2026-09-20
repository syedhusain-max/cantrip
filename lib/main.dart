import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/library_state.dart';
import 'state/user_data_store.dart';
import 'theme/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final store = UserDataStore();
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
