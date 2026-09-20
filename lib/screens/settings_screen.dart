import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../theme/theme_controller.dart';

/// The Settings tab: theme mode and a language section (English only for
/// now, with Arabic shown as a disabled placeholder for the future).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('settings.title'))),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 700
                ? 700.0
                : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: maxWidth,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _SectionCard(
                      title: strings.t('settings.appearance'),
                      child: SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: const Icon(Icons.light_mode_outlined),
                            label: Text(strings.t('settings.light')),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: const Icon(Icons.dark_mode_outlined),
                            label: Text(strings.t('settings.dark')),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: const Icon(Icons.brightness_auto_outlined),
                            label: Text(strings.t('settings.system')),
                          ),
                        ],
                        selected: {themeController.mode},
                        onSelectionChanged: (s) =>
                            themeController.setMode(s.first),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: strings.t('settings.language'),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(strings.t('settings.english')),
                            trailing: const Icon(Icons.check_circle),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            enabled: false,
                            title: Text(strings.t('settings.arabicComingSoon')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: strings.t('settings.about'),
                      child: Text(strings.t('settings.aboutBody')),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
