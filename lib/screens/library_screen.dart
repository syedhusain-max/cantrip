import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/taxonomy_registry.dart';
import '../data/tool_registry.dart';
import '../l10n/app_strings.dart';
import '../router/app_router.dart';
import '../state/library_state.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/prompt_card.dart';

/// Search, filter and browse the library.
///
/// The filter lives in the URL (`/library?tool=higgsfield`), which is what
/// makes a filtered view shareable and lets Home's browse shortcuts be
/// plain links. Changes made in the screen rewrite that URL with
/// [GoRouter.replace] rather than push, so filtering doesn't bury the
/// previous page under a stack of back-button steps.
class LibraryScreen extends StatefulWidget {
  final LibraryFilter initialFilter;

  const LibraryScreen({super.key, this.initialFilter = const LibraryFilter()});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late LibraryFilter _filter = widget.initialFilter;
  late final TextEditingController _searchController = TextEditingController(
    text: widget.initialFilter.search,
  );

  @override
  void didUpdateWidget(LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Arriving from a link (or a Home shortcut) while this tab is already
    // built: adopt the incoming filter instead of keeping the stale one.
    if (widget.initialFilter != oldWidget.initialFilter &&
        widget.initialFilter != _filter) {
      _filter = widget.initialFilter;
      _searchController.text = _filter.search;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _apply(LibraryFilter filter) {
    setState(() => _filter = filter);
    context.replace(Routes.libraryWith(filter));
  }

  /// A single-axis filter names itself in the app bar (the Home shortcuts
  /// all arrive this way); anything else falls back to the generic title.
  String _title(AppStrings strings) {
    if (_filter.search.isEmpty && _filter.activeCount == 1) {
      final label = switch (_filter) {
        LibraryFilter(:final toolId?) => toolName(toolId),
        LibraryFilter(:final useCaseId?) => useCaseLabel(useCaseId),
        LibraryFilter(:final nicheId?) => nicheLabel(nicheId),
        LibraryFilter(:final outputTypeId?) => outputTypeLabel(outputTypeId),
        LibraryFilter(:final inputMethodId?) => inputMethodLabel(inputMethodId),
        _ => null,
      };
      if (label != null) return label;
    }
    return strings.t('library.title');
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final library = context.watch<LibraryState>();
    final results = library.filtered(_filter);

    return Scaffold(
      appBar: AppBar(title: Text(_title(strings))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: strings.t('library.searchHint'),
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => _apply(_filter.copyWith(search: v)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Badge(
                    isLabelVisible: _filter.activeCount > 0,
                    label: Text('${_filter.activeCount}'),
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.tune),
                      tooltip: strings.t('library.filters'),
                      onPressed: () =>
                          FilterSheet.show(context, _filter, _apply),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Text(
                    '${results.length} ${results.length == 1 ? 'prompt' : 'prompts'}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (!_filter.isEmpty)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _apply(const LibraryFilter());
                      },
                      child: Text(strings.t('library.clearFilters')),
                    ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          strings.t('library.noResults'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final columns = w >= 1300
                            ? 4
                            : (w >= 980 ? 3 : (w >= 640 ? 2 : 1));
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisExtent: 272,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: results.length,
                          itemBuilder: (context, i) {
                            final item = results[i];
                            return PromptCard(
                              item: item,
                              status: library.statusFor(item.variant),
                              worksCount: library
                                  .signalsFor(item.variant)
                                  .works,
                              isFavourite: library.isFavourite(item.variant.id),
                              onToggleFavourite: () =>
                                  library.toggleFavourite(item.variant.id),
                              onTap: () =>
                                  context.push(Routes.prompt(item.variant.id)),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
