import 'package:flutter/material.dart';

import '../data/tool_registry.dart';

/// A pill showing a tool's name in its own accent colour.
///
/// Takes a tool id rather than an object so any list row can render a badge
/// from data alone. An unknown or null id falls back to a neutral pill,
/// which is what a tool-agnostic recipe shows.
class ToolBadge extends StatelessWidget {
  final String? toolId;
  final String fallbackLabel;
  final bool compact;

  const ToolBadge({
    super.key,
    required this.toolId,
    this.fallbackLabel = 'Multi-tool',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tool = toolById(toolId);
    final color = tool?.accent ?? scheme.outline;
    final label = tool?.name ?? fallbackLabel;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style:
            (compact
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.labelMedium)
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
