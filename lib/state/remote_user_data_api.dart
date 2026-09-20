import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fork.dart';
import '../models/prompt_folder.dart';
import 'user_data_store.dart';

/// The server side of user data, reduced to the handful of calls the app
/// actually makes.
///
/// [SyncedUserDataStore] talks to this rather than to Supabase directly, so
/// the sync rules — when to upload, when to trust the server — can be tested
/// without a network, and so swapping backends touches one file.
abstract interface class RemoteUserDataApi {
  /// Null when signed out, which is the app's normal browsing state.
  String? get currentUserId;

  Future<UserData> fetch(String userId);
  Future<void> replaceFavourites(String userId, Set<String> ids);
  Future<void> replaceSignals(String userId, Map<String, bool> signals);
  Future<void> replaceFolders(String userId, List<PromptFolder> folders);
  Future<void> deleteAll(String userId);
}

/// Supabase implementation of [RemoteUserDataApi].
///
/// Every write replaces the user's rows for that kind of data rather than
/// diffing. The data is a handful of rows per user, and a correct diff would
/// need change tracking the local store doesn't keep; when that stops being
/// true, this is the thing to revisit.
class SupabaseUserDataApi implements RemoteUserDataApi {
  final SupabaseClient client;

  const SupabaseUserDataApi(this.client);

  @override
  String? get currentUserId => client.auth.currentUser?.id;

  @override
  Future<UserData> fetch(String userId) async {
    final favourites = await client
        .from('favourites')
        .select('variant_id')
        .eq('user_id', userId);
    final signals = await client
        .from('signals')
        .select('variant_id, works')
        .eq('user_id', userId);
    final folders = await client
        .from('folders')
        .select('id, name, type, variable_defaults')
        .eq('user_id', userId);
    final forks = await client
        .from('forks')
        .select(
          'id, folder_id, source_variant_id, title, filled_values, '
          'source_verified_on, created_at',
        )
        .eq('user_id', userId);

    final forksByFolder = <String, List<Fork>>{};
    for (final row in forks) {
      final verifiedOn = DateTime.tryParse('${row['source_verified_on']}');
      if (verifiedOn == null) continue;
      (forksByFolder['${row['folder_id']}'] ??= []).add(
        Fork(
          id: '${row['id']}',
          sourceVariantId: '${row['source_variant_id']}',
          title: row['title'] as String?,
          values: _stringMap(row['filled_values']),
          sourceVerifiedOn: verifiedOn,
          createdAt: DateTime.tryParse('${row['created_at']}') ?? verifiedOn,
        ),
      );
    }

    return UserData(
      favouriteIds: {for (final row in favourites) '${row['variant_id']}'},
      signals: {
        for (final row in signals)
          if (row['works'] is bool)
            '${row['variant_id']}': row['works'] as bool,
      },
      folders: [
        for (final row in folders)
          PromptFolder(
            id: '${row['id']}',
            name: '${row['name']}',
            type: FolderType.values.firstWhere(
              (t) => t.name == row['type'],
              orElse: () => FolderType.personal,
            ),
            items: forksByFolder['${row['id']}'] ?? [],
            variableDefaults: _stringMap(row['variable_defaults']),
          ),
      ],
    );
  }

  @override
  Future<void> replaceFavourites(String userId, Set<String> ids) async {
    await client.from('favourites').delete().eq('user_id', userId);
    if (ids.isEmpty) return;
    await client.from('favourites').insert([
      for (final id in ids) {'user_id': userId, 'variant_id': id},
    ]);
  }

  @override
  Future<void> replaceSignals(String userId, Map<String, bool> signals) async {
    await client.from('signals').delete().eq('user_id', userId);
    if (signals.isEmpty) return;
    await client.from('signals').insert([
      for (final entry in signals.entries)
        {'user_id': userId, 'variant_id': entry.key, 'works': entry.value},
    ]);
  }

  @override
  Future<void> replaceFolders(String userId, List<PromptFolder> folders) async {
    // Forks cascade from folders, so this clears both.
    await client.from('folders').delete().eq('user_id', userId);
    if (folders.isEmpty) return;

    await client.from('folders').insert([
      for (final folder in folders)
        {
          'user_id': userId,
          'id': folder.id,
          'name': folder.name,
          'type': folder.type.name,
          'variable_defaults': folder.variableDefaults,
        },
    ]);

    final forks = [
      for (final folder in folders)
        for (final fork in folder.items)
          {
            'user_id': userId,
            'id': fork.id,
            'folder_id': folder.id,
            'source_variant_id': fork.sourceVariantId,
            'title': fork.title,
            'filled_values': fork.values,
            'source_verified_on': _asDate(fork.sourceVerifiedOn),
            'created_at': fork.createdAt.toIso8601String(),
          },
    ];
    if (forks.isEmpty) return;
    await client.from('forks').insert(forks);
  }

  @override
  Future<void> deleteAll(String userId) async {
    await client.from('folders').delete().eq('user_id', userId);
    await client.from('favourites').delete().eq('user_id', userId);
    await client.from('signals').delete().eq('user_id', userId);
  }

  static String _asDate(DateTime value) =>
      value.toIso8601String().split('T').first;

  static Map<String, String> _stringMap(Object? raw) => {
    if (raw is Map)
      for (final entry in raw.entries) '${entry.key}': '${entry.value}',
  };
}
