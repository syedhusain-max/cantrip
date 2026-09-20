import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_strings.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class CantripApp extends StatefulWidget {
  const CantripApp({super.key});

  @override
  State<CantripApp> createState() => _CantripAppState();
}

class _CantripAppState extends State<CantripApp> {
  // Built once: recreating the router on rebuild would reset navigation
  // state on every theme change.
  late final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return MaterialApp.router(
      title: 'Cantrip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeController.mode,
      // English only for now; add Locale('ar') here once Arabic strings
      // are added to lib/l10n/app_strings.dart.
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
