import 'package:flutter/material.dart';

import '../data/tool_registry.dart';
import '../l10n/app_strings.dart';
import '../models/author_note.dart';
import '../models/freshness.dart';
import '../state/author_notes_controller.dart';
import '../utils/date_format.dart';

/// Shows what the author found when they ran the prompt, and any badges
/// the prompt has earned.
///
/// Two rules shape this widget, both of them about not overclaiming:
///
/// 1. **An untested prompt says so.** The bundled library carries
///    verification dates that came with the content, not from anyone
///    running it. Where nobody has tested it, this says that plainly
///    rather than letting a shipped date imply a test.
/// 2. **Whose claim it is, is always visible.** The author's badges are
///    labelled as the author's; community badges are labelled as users'.
///    A reader should never have to guess who is vouching.
class AuthorNoteCard extends StatelessWidget {
  final AuthorNote? note;
  final List<PromptBadge> badges;
  final FreshnessSignals signals;

  const AuthorNoteCard({
    super.key,
    required this.note,
    required this.badges,
    required this.signals,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final n = note;

    if (n == null && badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.science_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                strings.t('author.untestedNote'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badges.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [for (final b in badges) _Badge(badge: b)],
            ),
            const SizedBox(height: 12),
          ],
          if (n != null) ...[
            Row(
              children: [
                Icon(
                  n.isVerified
                      ? Icons.verified_outlined
                      : Icons.science_outlined,
                  size: 18,
                  color: n.verdict == AuthorVerdict.broken
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  n.verdict.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (n.testedOn != null) ...[
              const SizedBox(height: 6),
              Text(
                '${strings.t('detail.lastVerified')} '
                '${formatDate(n.testedOn!)}'
                '${n.testedModelLabel == null ? '' : ' · ${n.testedModelLabel}'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            // Two lists rather than a verdict, because "works on v6.1,
            // fails on v7" is the single most useful fact about a prompt.
            if (n.worksOn.isNotEmpty || n.failsOn.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final m in n.worksOn) _ModelChip(label: m, works: true),
                  for (final m in n.failsOn) _ModelChip(label: m, works: false),
                ],
              ),
            ],
            if (n.bestInToolId != null) ...[
              const SizedBox(height: 10),
              Text(
                'Best results in ${toolName(n.bestInToolId)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (n.note != null) ...[
              const SizedBox(height: 10),
              Text(n.note!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final PromptBadge badge;

  const _Badge({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.strings;
    final isWarning = badge == PromptBadge.redFlag;
    final colour = isWarning
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.secondaryContainer;
    final onColour = isWarning
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: onColour,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          // Who is vouching, always on the badge itself.
          Text(
            badge.isAuthorOpinion
                ? strings.t('author.byAuthor')
                : strings.t('author.byCommunity'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: onColour.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelChip extends StatelessWidget {
  final String label;
  final bool works;

  const _ModelChip({required this.label, required this.works});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: works ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            works ? Icons.check : Icons.close,
            size: 13,
            color: works ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
          const SizedBox(width: 5),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
