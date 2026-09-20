import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/prompt_folder.dart';
import '../state/library_state.dart';
import '../widgets/tool_badge.dart';
import 'prompt_detail_screen.dart';

/// The saved prompts inside one folder.
class FolderScreen extends StatelessWidget {
  final String folderId;

  const FolderScreen({super.key, required this.folderId});

  void _rename(
    BuildContext context,
    LibraryState library,
    String forkId,
    String currentTitle,
  ) {
    final strings = context.strings;
    final controller = TextEditingController(text: currentTitle);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('common.rename')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              library.renameFork(folderId, forkId, controller.text.trim());
              Navigator.of(dialogContext).pop();
            },
            child: Text(strings.t('common.save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final library = context.watch<LibraryState>();
    final folder = library.folderById(folderId);

    if (folder == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(strings.t('saved.folderMissing'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                folder.type.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
      body: folder.items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  strings.t('saved.emptyFolderItems'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: folder.items.length,
              itemBuilder: (context, i) {
                final fork = folder.items[i];
                final source = library.sourceOf(fork);

                // The library prompt this copy points at can be gone if the
                // bundled library changed under it.
                if (source == null) {
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.link_off,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        fork.title ?? strings.t('saved.forkOrphaned'),
                      ),
                      subtitle: Text(strings.t('saved.forkOrphanedBody')),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            library.removeFromFolder(folderId, fork.id),
                      ),
                    ),
                  );
                }

                final goal = library.goalById(source.goalId);
                final filledCount = fork.values.values
                    .where((v) => v.trim().isNotEmpty)
                    .length;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    title: Text(
                      fork.title ?? source.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ToolBadge(toolId: source.toolId, compact: true),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  goal?.title ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            ],
                          ),
                          if (filledCount > 0 ||
                              library.hasUpstreamUpdate(fork))
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 4,
                                children: [
                                  if (filledCount > 0)
                                    Text(
                                      '$filledCount ${strings.t('saved.valuesSaved')}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  if (library.hasUpstreamUpdate(fork))
                                    Text(
                                      strings.t('saved.upstreamUpdated'),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.tertiary,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PromptDetailScreen(
                          variantId: source.id,
                          folderId: folderId,
                          forkId: fork.id,
                        ),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'rename') {
                          _rename(
                            context,
                            library,
                            fork.id,
                            fork.title ?? source.title,
                          );
                        } else if (action == 'remove') {
                          library.removeFromFolder(folderId, fork.id);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text(strings.t('common.rename')),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(strings.t('saved.removeFromFolder')),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
