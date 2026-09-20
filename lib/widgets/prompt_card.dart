import 'package:flutter/material.dart';

import '../data/taxonomy_registry.dart';
import '../models/freshness.dart';
import '../state/library_state.dart';
import '../utils/date_format.dart';
import 'freshness_pill.dart';
import 'tool_badge.dart';

/// A library row: which tool, what goal, what it outputs, and whether it
/// still works.
class PromptCard extends StatelessWidget {
  final LibraryItem item;
  final FreshnessStatus status;
  final int worksCount;
  final VoidCallback onTap;
  final bool isFavourite;
  final VoidCallback? onToggleFavourite;

  const PromptCard({
    super.key,
    required this.item,
    required this.status,
    required this.worksCount,
    required this.onTap,
    this.isFavourite = false,
    this.onToggleFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = item.goal;
    final variant = item.variant;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ToolBadge(toolId: variant.toolId),
                  const SizedBox(width: 8),
                  // Flexible, not Expanded: the pill should hug its label
                  // and only shrink when the row actually runs out of room.
                  Flexible(child: FreshnessPill(status: status, compact: true)),
                  const Spacer(),
                  if (onToggleFavourite != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: isFavourite
                          ? 'Remove from favourites'
                          : 'Add to favourites',
                      icon: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                      ),
                      color: isFavourite ? theme.colorScheme.error : null,
                      onPressed: onToggleFavourite,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                variant.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                goal.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _MetaChip(
                    icon:
                        useCaseById(goal.useCaseId)?.icon ??
                        Icons.label_outline,
                    label: useCaseLabel(goal.useCaseId),
                  ),
                  _MetaChip(
                    icon:
                        outputTypeById(goal.outputTypeId)?.icon ??
                        Icons.label_outline,
                    label: outputTypeLabel(goal.outputTypeId),
                  ),
                  if (variant.isRecipe)
                    _MetaChip(
                      icon: Icons.route_outlined,
                      label: '${variant.steps.length} steps',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text('$worksCount', style: theme.textTheme.labelSmall),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formatDate(variant.freshness.verifiedOn),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
