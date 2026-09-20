import 'package:flutter/material.dart';

import '../models/freshness.dart';

/// Shows how much a prompt can currently be trusted.
///
/// This replaces the star rating on list rows. Stars average a subjective
/// judgement; this answers the question that actually decides whether to
/// spend generation credits — does it still work on the current model.
class FreshnessPill extends StatelessWidget {
  final FreshnessStatus status;
  final bool compact;

  const FreshnessPill({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (fg, bg) = switch (status) {
      FreshnessStatus.verified => (
        scheme.brightness == Brightness.dark
            ? const Color(0xFF63C9AA)
            : const Color(0xFF0B6E56),
        scheme.brightness == Brightness.dark
            ? const Color(0xFF10332B)
            : const Color(0xFFDDF0E9),
      ),
      FreshnessStatus.aging => (
        scheme.brightness == Brightness.dark
            ? const Color(0xFFDFAE55)
            : const Color(0xFF93650B),
        scheme.brightness == Brightness.dark
            ? const Color(0xFF33270F)
            : const Color(0xFFF7EBD3),
      ),
      FreshnessStatus.needsReview => (
        scheme.brightness == Brightness.dark
            ? const Color(0xFFDFAE55)
            : const Color(0xFF93650B),
        scheme.brightness == Brightness.dark
            ? const Color(0xFF33270F)
            : const Color(0xFFF7EBD3),
      ),
      FreshnessStatus.broken => (scheme.error, scheme.errorContainer),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 11 : 13, color: fg),
          const SizedBox(width: 4),
          // Flexible so a long status ("Reported broken") ellipsizes inside
          // a narrow card rather than overflowing the row.
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
