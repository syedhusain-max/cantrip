import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/prompt_folder.dart';
import '../router/app_router.dart';
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

class _FoldersTab extends StatelessWidget {
  const _FoldersTab();

  void _createFolder(BuildContext context, LibraryState library) {
    final strings = context.strings;
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
          : ListView.builder(
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
                      onPressed: () => _confirmDelete(context, library, folder),
                    ),
                    onTap: () => context.push(Routes.folder(folder.id)),
                  ),
                );
              },
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
