import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../state/library_state.dart';
import '../widgets/step_card.dart';

/// Walks a multi-step recipe one step at a time.
///
/// The thing this screen exists to solve is the hand-off between steps:
/// when step 2 consumes what step 1 produced, the user has to go and get
/// that artefact from the tool. So each completed step offers a note field
/// for what it produced, and the next step shows it — the carry-forward is
/// visible rather than something the user has to hold in their head.
class RecipeRunnerScreen extends StatefulWidget {
  final String variantId;

  /// What the user already filled in on the detail screen. Empty when the
  /// runner is reached by a cold link, in which case steps show raw tokens.
  final Map<String, String> values;

  const RecipeRunnerScreen({
    super.key,
    required this.variantId,
    required this.values,
  });

  @override
  State<RecipeRunnerScreen> createState() => _RecipeRunnerScreenState();
}

class _RecipeRunnerScreenState extends State<RecipeRunnerScreen> {
  int _current = 0;
  final Set<int> _done = {};

  /// What each step produced, keyed by the step's output id.
  final Map<String, String> _producedNotes = {};

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.strings.t('common.copiedPrompt')),
        behavior: SnackBarBehavior.floating,
        width: 320,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final variant = context.watch<LibraryState>().variantById(widget.variantId);
    if (variant == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.t('runner.title'))),
        body: Center(child: Text(strings.t('detail.missing'))),
      );
    }
    final steps = variant.steps;
    final step = steps[_current];
    final isLast = _current == steps.length - 1;

    // Notes recorded by earlier steps that this one consumes.
    final carried = [
      for (final input in step.inputs)
        if (input.fromStepOutputId != null &&
            _producedNotes[input.fromStepOutputId] != null)
          (
            label: input.label ?? input.fromStepOutputId!,
            note: _producedNotes[input.fromStepOutputId]!,
          ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('runner.title')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_current + 1) / steps.length,
            minHeight: 4,
          ),
        ),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text(
                      '${strings.t('detail.step')} ${_current + 1} / ${steps.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (carried.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.subdirectory_arrow_right,
                                  size: 16,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  strings.t('runner.carriedForward'),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final c in carried)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${c.label}: ${c.note}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    StepCard(
                      step: step,
                      variant: variant,
                      values: widget.values,
                      onCopy: _copy,
                    ),

                    if (step.produces != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        strings.t('runner.whatDidYouGet'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.produces!.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey('note-${step.produces!.id}'),
                        initialValue: _producedNotes[step.produces!.id] ?? '',
                        decoration: InputDecoration(
                          hintText: strings.t('runner.notePlaceholder'),
                        ),
                        onChanged: (v) => setState(
                          () => _producedNotes[step.produces!.id] = v,
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),
                    Row(
                      children: [
                        if (_current > 0)
                          OutlinedButton(
                            onPressed: () => setState(() => _current -= 1),
                            child: Text(strings.t('wizard.back')),
                          ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () {
                            setState(() => _done.add(_current));
                            if (isLast) {
                              context.pop();
                            } else {
                              setState(() => _current += 1);
                            }
                          },
                          icon: Icon(
                            isLast ? Icons.check : Icons.arrow_forward,
                            size: 18,
                          ),
                          label: Text(
                            isLast
                                ? strings.t('runner.finish')
                                : strings.t('runner.nextStep'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    // Jump between steps without losing notes.
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < steps.length; i++)
                          ChoiceChip(
                            avatar: _done.contains(i)
                                ? const Icon(Icons.check, size: 15)
                                : null,
                            label: Text('${i + 1}. ${steps[i].title}'),
                            selected: i == _current,
                            onSelected: (_) => setState(() => _current = i),
                          ),
                      ],
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
