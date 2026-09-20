import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/taxonomy_registry.dart';
import '../data/tool_registry.dart';
import '../l10n/app_strings.dart';
import '../models/freshness.dart';
import '../state/library_state.dart';
import '../widgets/prompt_card.dart';
import '../widgets/tool_badge.dart';
import 'prompt_detail_screen.dart';

/// The guided flow: goal, then what you have to start from, then which
/// tools you can actually use — ending on one recommendation with
/// alternatives for other tools.
///
/// The tool question is multi-select on purpose. Example 4 in the brief
/// ("a full brand kit", no tool named) can only be routed well if the app
/// knows what the user has access to.
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  int _step = 0;
  String? _useCaseId;
  String? _inputMethodId;
  final Set<String> _toolIds = {};
  bool _toolsAnswered = false;

  void _reset() => setState(() {
    _step = 0;
    _useCaseId = null;
    _inputMethodId = null;
    _toolIds.clear();
    _toolsAnswered = false;
  });

  /// Scores every variant against the answers and returns the best plus one
  /// alternative per other tool.
  ///
  /// Scoring rather than filtering: with a small library an exact match on
  /// all three answers often doesn't exist, and returning nothing would be
  /// a dead end. A close match with the mismatch visible is more useful.
  ({LibraryItem? best, List<LibraryItem> alternatives}) _recommend(
    LibraryState library,
  ) {
    if (_useCaseId == null) return (best: null, alternatives: const []);

    final candidates = library.allItems
        .where((i) => i.goal.useCaseId == _useCaseId)
        .toList();
    if (candidates.isEmpty) return (best: null, alternatives: const []);

    int score(LibraryItem item) {
      var s = 0;
      if (_inputMethodId != null &&
          item.variant.inputMethodId == _inputMethodId) {
        s += 4;
      }
      if (_toolsAnswered && _toolIds.isNotEmpty) {
        final involved = {
          if (item.variant.toolId != null) item.variant.toolId!,
          ...item.variant.involvedToolIds,
        };
        if (involved.isNotEmpty && involved.every(_toolIds.contains)) {
          // Every tool the recipe needs is available to the user.
          s += 8;
        } else if (involved.any(_toolIds.contains)) {
          // At least one is.
          s += 3;
        }
        // A tool-agnostic recipe fits whatever they have.
        if (item.variant.toolId == null) s += 2;
      }
      if (!library.statusFor(item.variant).demoteInSearch) s += 2;
      return s;
    }

    candidates.sort((a, b) {
      final byScore = score(b).compareTo(score(a));
      if (byScore != 0) return byScore;
      return b.variant.freshness.verifiedOn.compareTo(
        a.variant.freshness.verifiedOn,
      );
    });

    final best = candidates.first;
    final seen = <String?>{best.variant.toolId};
    final alternatives = <LibraryItem>[];
    for (final c in candidates.skip(1)) {
      if (seen.contains(c.variant.toolId)) continue;
      seen.add(c.variant.toolId);
      alternatives.add(c);
    }
    return (best: best, alternatives: alternatives);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final library = context.watch<LibraryState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('wizard.title')),
        actions: [
          if (_step > 0)
            TextButton(
              onPressed: _reset,
              child: Text(strings.t('wizard.startOver')),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 760
                ? 760.0
                : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: width,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _Progress(step: _step),
                    const SizedBox(height: 22),
                    if (_step == 0) _goalStep(strings),
                    if (_step == 1) _inputStep(strings),
                    if (_step == 2) _toolStep(strings),
                    if (_step == 3) _resultStep(strings, library),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _goalStep(AppStrings strings) => _Card(
    title: strings.t('wizard.stepGoalTitle'),
    subtitle: strings.t('wizard.stepGoalHint'),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final t in useCases)
          ChoiceChip(
            avatar: Icon(t.icon, size: 17),
            label: Text(t.label),
            selected: _useCaseId == t.id,
            onSelected: (_) => setState(() {
              _useCaseId = t.id;
              _step = 1;
            }),
          ),
      ],
    ),
  );

  Widget _inputStep(AppStrings strings) => _Card(
    title: strings.t('wizard.stepInputTitle'),
    subtitle: strings.t('wizard.stepInputHint'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final t in inputMethods)
              ChoiceChip(
                avatar: Icon(t.icon, size: 17),
                label: Text(t.label),
                selected: _inputMethodId == t.id,
                onSelected: (_) => setState(() {
                  _inputMethodId = t.id;
                  _step = 2;
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => setState(() => _step = 0),
          child: Text(strings.t('wizard.back')),
        ),
      ],
    ),
  );

  Widget _toolStep(AppStrings strings) => _Card(
    title: strings.t('wizard.stepToolTitle'),
    subtitle: strings.t('wizard.stepToolHint'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final tool in toolRegistry)
              FilterChip(
                label: Text(tool.name),
                selected: _toolIds.contains(tool.id),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _toolIds.add(tool.id);
                  } else {
                    _toolIds.remove(tool.id);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 1),
              child: Text(strings.t('wizard.back')),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => setState(() {
                _toolsAnswered = true;
                _step = 3;
              }),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                _toolIds.isEmpty
                    ? strings.t('wizard.anyTool')
                    : strings.t('wizard.showResult'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _resultStep(AppStrings strings, LibraryState library) {
    final result = _recommend(library);
    final best = result.best;

    if (best == null) {
      return _Card(
        title: strings.t('wizard.recommended'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.t('wizard.noMatches')),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => setState(() => _step = 2),
              child: Text(strings.t('wizard.back')),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.t('wizard.recommended'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.t('wizard.recommendedHint'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 272,
          child: PromptCard(
            item: best,
            status: library.statusFor(best.variant),
            worksCount: library.signalsFor(best.variant).works,
            isFavourite: library.isFavourite(best.variant.id),
            onToggleFavourite: () => library.toggleFavourite(best.variant.id),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PromptDetailScreen(variantId: best.variant.id),
              ),
            ),
          ),
        ),
        if (result.alternatives.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text(
            strings.t('wizard.alternatives'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (final alt in result.alternatives)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                tileColor: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                leading: ToolBadge(
                  toolId: alt.variant.toolId,
                  fallbackLabel: strings.t('detail.noToolPreselected'),
                  compact: true,
                ),
                title: Text(
                  alt.variant.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  inputMethodLabel(alt.variant.inputMethodId),
                  style: theme.textTheme.labelSmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PromptDetailScreen(variantId: alt.variant.id),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () => setState(() => _step = 2),
          child: Text(strings.t('wizard.back')),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  final int step;
  const _Progress({required this.step});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= step
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i != 3) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Card({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}
