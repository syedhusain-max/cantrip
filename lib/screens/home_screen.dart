import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/taxonomy_registry.dart';
import '../data/tool_registry.dart';
import '../l10n/app_strings.dart';
import '../router/app_router.dart';
import '../state/library_state.dart';
import '../widgets/section_header.dart';
import '../widgets/tool_badge.dart';

/// The Home tab: the guided-flow entry point, plus browse shortcuts into
/// the library along three of the five axes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Browse shortcuts switch to the Library tab with the filter in the URL,
  /// so the filtered view is linkable and the tab bar stays put.
  void _browse(BuildContext context, LibraryFilter filter) =>
      context.go(Routes.libraryWith(filter));

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('app.name'))),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 900
                ? 900.0
                : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: width,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _GuidedFlowCard(onStart: () => context.go(Routes.create)),
                    const SizedBox(height: 30),

                    SectionHeader(
                      title: strings.t('home.browseByTool'),
                      actionLabel: strings.t('home.viewAll'),
                      onAction: () => _browse(context, const LibraryFilter()),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tool in toolRegistry)
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => _browse(
                              context,
                              LibraryFilter(toolId: tool.id),
                            ),
                            child: ToolBadge(toolId: tool.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    SectionHeader(title: strings.t('home.browseByUseCase')),
                    const SizedBox(height: 12),
                    _TileGrid(
                      tiles: [
                        for (final t in useCases)
                          _Tile(
                            icon: t.icon,
                            label: t.label,
                            onTap: () => _browse(
                              context,
                              LibraryFilter(useCaseId: t.id),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    SectionHeader(title: strings.t('home.browseByOutput')),
                    const SizedBox(height: 12),
                    _TileGrid(
                      tiles: [
                        for (final t in outputTypes)
                          _Tile(
                            icon: t.icon,
                            label: t.label,
                            onTap: () => _browse(
                              context,
                              LibraryFilter(outputTypeId: t.id),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
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

class _GuidedFlowCard extends StatelessWidget {
  final VoidCallback? onStart;

  const _GuidedFlowCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome,
              color: scheme.onPrimaryContainer,
              size: 26,
            ),
            const SizedBox(height: 14),
            Text(
              strings.t('home.greeting'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.t('home.subtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(strings.t('home.startGuided')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.label, required this.onTap});
}

/// Fixed-width tiles that wrap, so a row never stretches one tile across
/// dead space when the count doesn't divide evenly.
class _TileGrid extends StatelessWidget {
  final List<_Tile> tiles;

  const _TileGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final t in tiles)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: t.onTap,
            child: Container(
              width: 164,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(t.icon, color: scheme.primary, size: 20),
                  const SizedBox(height: 10),
                  Text(
                    t.label,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
