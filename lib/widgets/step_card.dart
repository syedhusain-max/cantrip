import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/prompt_step.dart';
import '../models/prompt_variant.dart';
import 'tool_badge.dart';

/// One step, rendered with its variables already substituted.
///
/// Handles the non-prompt cases properly: an upload or export step shows
/// the path through the tool's UI instead of a paste box, because there is
/// nothing to paste.
class StepCard extends StatelessWidget {
  final PromptStep step;
  final PromptVariant variant;
  final Map<String, String> values;
  final bool showStepNumber;
  final ValueChanged<String> onCopy;

  const StepCard({
    super.key,
    required this.step,
    required this.variant,
    required this.values,
    required this.onCopy,
    this.showStepNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final prompt = step.hasPromptText
        ? variant.render(step.prompt!, values)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showStepNumber) ...[
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${step.order}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            step.actionType.icon,
                            size: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            step.actionType.label,
                            style: theme.textTheme.labelSmall,
                          ),
                          if (step.estMinutes != null) ...[
                            const SizedBox(width: 10),
                            Icon(
                              Icons.schedule,
                              size: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '~${step.estMinutes} min',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (step.toolId != null)
                  ToolBadge(toolId: step.toolId, compact: true),
              ],
            ),

            // Suggested tools, for steps with nothing preselected.
            if (step.toolId == null && step.suggestedToolIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${strings.t('detail.suggestedTools')}:',
                    style: theme.textTheme.labelSmall,
                  ),
                  for (final id in step.suggestedToolIds)
                    ToolBadge(toolId: id, compact: true),
                ],
              ),
            ],

            // What this step consumes — named explicitly so a recipe reads
            // as a chain rather than a list.
            if (step.inputs.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final input in step.inputs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Icon(
                        input.isCarriedForward
                            ? Icons.subdirectory_arrow_right
                            : Icons.input,
                        size: 13,
                        color: input.isCarriedForward
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          input.isCarriedForward
                              ? '${strings.t('detail.fromStep')}: ${input.label ?? input.fromStepOutputId}'
                              : '${strings.t('detail.usesInput')}: ${input.label ?? input.variableKey}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: input.isCarriedForward
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // Where in the tool's UI, for steps that aren't a prompt.
            if (step.where != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.navigation_outlined,
                      size: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        step.where!,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (prompt != null) ...[
              const SizedBox(height: 12),
              _CodeBlock(text: prompt),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => onCopy(prompt),
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: Text(strings.t('detail.copyPrompt')),
                ),
              ),
            ],

            if (step.negativePrompt != null) ...[
              const SizedBox(height: 12),
              Text(
                strings.t('detail.negativePrompt'),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              _CodeBlock(text: variant.render(step.negativePrompt!, values)),
            ],

            if (step.settings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                strings.t('detail.settings'),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final e in step.settings.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          e.key,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          variant.render(e.value, values),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 12),
            Text(
              '${strings.t('detail.expectedOutput')}: ${step.expectedOutput}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),

            // The publish gate requires at least one stated limitation, so
            // this is never decoration — it's the part that saves a run.
            if (step.guardrails.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final g in step.guardrails)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: scheme.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          g,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String text;
  const _CodeBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: SelectableText(
        text,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontFamily: 'monospace', height: 1.55),
      ),
    );
  }
}
