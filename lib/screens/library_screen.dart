import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../state/library_state.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/prompt_card.dart';
import 'prompt_detail_screen.dart';

/// Search, filter and browse the library. Used as the Library tab and
/// pushed with an [initialFilter] from Home's browse shortcuts.
class LibraryScreen extends StatefulWidget {
  final LibraryFilter initialFilter;
  final String? title;

  const LibraryScreen({
    super.key,
    this.initialFilter = const LibraryFilter(),
    this.title,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late LibraryFilter _filter = widget.initialFilter;
  late final TextEditingController _searchController = TextEditingController(
    text: widget.initialFilter.search,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final library = context.watch<LibraryState>();
    final results = library.filtered(_filter);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? strings.t('library.title'))),
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
                      onChanged: (v) =>
                          setState(() => _filter = _filter.copyWith(search: v)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Badge(
                    isLabelVisible: _filter.activeCount > 0,
                    label: Text('${_filter.activeCount}'),
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.tune),
                      tooltip: strings.t('library.filters'),
                      onPressed: () => FilterSheet.show(
                        context,
                        _filter,
                        (f) => setState(() => _filter = f),
                      ),
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
                      onPressed: () => setState(() {
                        _filter = const LibraryFilter();
                        _searchController.clear();
                      }),
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
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PromptDetailScreen(
                                    variantId: item.variant.id,
                                  ),
                                ),
                              ),
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
