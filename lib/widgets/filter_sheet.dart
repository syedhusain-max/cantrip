import 'package:flutter/material.dart';

import '../data/taxonomy_registry.dart';
import '../data/tool_registry.dart';
import '../l10n/app_strings.dart';
import '../models/taxonomy.dart';
import '../state/library_state.dart';

/// Edits a [LibraryFilter] across all five axes.
///
/// Options are built from the registries, so a new tool or niche appears
/// here automatically.
class FilterSheet extends StatefulWidget {
  final LibraryFilter initial;
  final ValueChanged<LibraryFilter> onApply;

  const FilterSheet({super.key, required this.initial, required this.onApply});

  static Future<void> show(
    BuildContext context,
    LibraryFilter initial,
    ValueChanged<LibraryFilter> onApply,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FilterSheet(initial: initial, onApply: onApply),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late LibraryFilter _filter = widget.initial;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    strings.t('library.filters'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        setState(() => _filter = const LibraryFilter()),
                    child: Text(strings.t('library.clearFilters')),
                  ),
                ],
              ),
              _Group(
                title: strings.t('filter.tool'),
                options: [
                  for (final t in toolRegistry) (id: t.id, label: t.name),
                ],
                selectedId: _filter.toolId,
                onSelected: (id) => setState(
                  () => _filter = _filter.copyWith(
                    toolId: id,
                    clearTool: id == null,
                  ),
                ),
              ),
              _Group(
                title: strings.t('filter.useCase'),
                options: _fromTaxa(useCases),
                selectedId: _filter.useCaseId,
                onSelected: (id) => setState(
                  () => _filter = _filter.copyWith(
                    useCaseId: id,
                    clearUseCase: id == null,
                  ),
                ),
              ),
              _Group(
                title: strings.t('filter.niche'),
                options: _fromTaxa(niches),
                selectedId: _filter.nicheId,
                onSelected: (id) => setState(
                  () => _filter = _filter.copyWith(
                    nicheId: id,
                    clearNiche: id == null,
                  ),
                ),
              ),
              _Group(
                title: strings.t('filter.outputType'),
                options: _fromTaxa(outputTypes),
                selectedId: _filter.outputTypeId,
                onSelected: (id) => setState(
                  () => _filter = _filter.copyWith(
                    outputTypeId: id,
                    clearOutputType: id == null,
                  ),
                ),
              ),
              _Group(
                title: strings.t('filter.inputMethod'),
                options: _fromTaxa(inputMethods),
                selectedId: _filter.inputMethodId,
                onSelected: (id) => setState(
                  () => _filter = _filter.copyWith(
                    inputMethodId: id,
                    clearInputMethod: id == null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(_filter);
                    Navigator.of(context).pop();
                  },
                  child: Text(strings.t('filter.apply')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<({String id, String label})> _fromTaxa(List<Taxon> taxa) => [
    for (final t in taxa) (id: t.id, label: t.label),
  ];
}

class _Group extends StatelessWidget {
  final String title;
  final List<({String id, String label})> options;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _Group({
    required this.title,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                FilterChip(
                  label: Text(o.label),
                  selected: selectedId == o.id,
                  onSelected: (isSelected) =>
                      onSelected(isSelected ? o.id : null),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
