import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../models/entitlement.dart';

/// What Pro is, shown either from Settings or at the moment a limit is hit.
///
/// When it opens because of a limit, that limit's explanation leads. A
/// paywall that answers the question the user just asked ("why can't I add
/// another folder?") reads as an answer; a generic feature grid reads as a
/// toll booth.
class ProScreen extends StatelessWidget {
  final LimitHit? hit;

  const ProScreen({super.key, this.hit});

  static String? _reasonKey(LimitHit? hit) => switch (hit) {
    LimitHit.folders => 'pro.limitFolders',
    LimitHit.savedCopies => 'pro.limitSavedCopies',
    LimitHit.folderDefaults => 'pro.limitFolderDefaults',
    LimitHit.export => 'pro.limitExport',
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final reason = _reasonKey(hit);

    const features = [
      'pro.featureFolders',
      'pro.featureSavedCopies',
      'pro.featureDefaults',
      'pro.featureAlerts',
      'pro.featureEarly',
      'pro.featureExport',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('pro.title'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reason != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        strings.t(reason),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    strings.t('pro.pitch'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final key in features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(strings.t(key))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  // No purchase button until there is something to buy.
                  // A dead "Subscribe" is worse than an honest note.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.t('pro.comingSoon'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.t('pro.comingSoonBody'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.canPop() ? context.pop() : null,
                      child: Text(strings.t('pro.notNow')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
