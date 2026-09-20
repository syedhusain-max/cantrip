import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/prompt_folder.dart';
import '../router/app_router.dart';
import '../state/entitlement_controller.dart';
import '../state/entitlement_gate.dart';
import '../state/library_state.dart';
import '../widgets/prompt_card.dart';

/// Favourited prompts, and folders holding forked editable copies.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.t('saved.title')),
          bottom: TabBar(
            tabs: [
              Tab(text: strings.t('saved.favouritesTab')),
              Tab(text: strings.t('saved.foldersTab')),
            ],
          ),
        ),
        body: const TabBarView(children: [_FavouritesTab(), _FoldersTab()]),
      ),
    );
  }
}

class _FavouritesTab extends StatelessWidget {
  const _FavouritesTab();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final library = context.watch<LibraryState>();
    final favourites = library.favourites;

    if (favourites.isEmpty) {
      return _Empty(
        icon: Icons.favorite_border,
        message: strings.t('saved.emptyFavourites'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w >= 1300 ? 4 : (w >= 980 ? 3 : (w >= 640 ? 2 : 1));
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 272,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: favourites.length,
          itemBuilder: (context, i) {
            final item = favourites[i];
            return PromptCard(
              item: item,
              status: library.statusFor(item.variant),
              worksCount: library.signalsFor(item.variant).works,
              isFavourite: true,
              onToggleFavourite: () => library.toggleFavourite(item.variant.id),
              onTap: () => context.push(Routes.prompt(item.variant.id)),
            );
          },
        );
      },
    );
  }
}

/// Shown to Pro users when a saved copy's source has broken or vanished.
///
/// The reassurance in the body is the important half: a saved copy is a
/// reference plus overrides, so the user's own version is untouched by the
/// library moving on. Without that line the banner reads as data loss.
class _AttentionBanner extends StatelessWidget {
  final int count;

  const _AttentionBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${strings.t(count == 1 ? 'saved.needsAttentionOne' : 'saved.needsAttention')}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.t('saved.needsAttentionBody'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoldersTab extends StatelessWidget {
  const _FoldersTab();

  void _createFolder(BuildContext context, LibraryState library) {
    final strings = context.strings;
    // Checked before the dialog opens: letting someone name a folder and
    // then refusing it is worse than saying so up front.
    final gate = EntitlementGate(
      limits: context.read<EntitlementController>().limits,
      library: library,
    );
    final blocked = gate.checkNewFolder();
    if (blocked != null) {
      context.push(Routes.pro(because: 'folders'));
      return;
    }
    final controller = TextEditingController();
    var type = FolderType.personal;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(strings.t('saved.newFolder')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: strings.t('saved.newFolderName'),
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<FolderType>(
                segments: [
                  ButtonSegment(
                    value: FolderType.personal,
                    label: Text(strings.t('saved.personal')),
                  ),
                  ButtonSegment(
                    value: FolderType.client,
                    label: Text(strings.t('saved.client')),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (s) => setDialogState(() => type = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.t('common.cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                library.createFolder(controller.text.trim(), type);
                Navigator.of(dialogContext).pop();
              },
              child: Text(strings.t('common.create')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    LibraryState library,
    PromptFolder folder,
  ) {
    final strings = context.strings;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('saved.deleteFolder')),
        content: Text(
          '${strings.t('saved.deleteFolderBody')} "${folder.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.t('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              library.deleteFolder(folder.id);
              Navigator.of(dialogContext).pop();
            },
            child: Text(strings.t('common.delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final library = context.watch<LibraryState>();
    final folders = library.folders;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createFolder(context, library),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: Text(strings.t('saved.newFolder')),
      ),
      body: folders.isEmpty
          ? _Empty(
              icon: Icons.folder_outlined,
              message: strings.t('saved.emptyFolders'),
            )
          : Column(
              children: [
                // Pro only: free users see this feature offered on the Pro
                // screen instead. Showing the alert to everyone and then
                // charging to act on it would be the worse kind of paywall.
                if (context
                    .watch<EntitlementController>()
                    .limits
                    .breakageAlerts)
                  if (library.savedCopiesNeedingAttention.isNotEmpty)
                    _AttentionBanner(
                      count: library.savedCopiesNeedingAttention.length,
                    ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: folders.length,
                    itemBuilder: (context, i) {
                      final folder = folders[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: Icon(
                              folder.type == FolderType.personal
                                  ? Icons.person_outline
                                  : Icons.business_outlined,
                              size: 20,
                            ),
                          ),
                          title: Text(folder.name),
                          subtitle: Text(
                            '${folder.type.label} · ${folder.items.length} ${folder.items.length == 1 ? 'prompt' : 'prompts'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: strings.t('saved.deleteFolder'),
                            onPressed: () =>
                                _confirmDelete(context, library, folder),
                          ),
                          onTap: () => context.push(Routes.folder(folder.id)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;

  const _Empty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: scheme.outline),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
