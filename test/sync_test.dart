import 'package:flutter_test/flutter_test.dart';
import 'package:cantrip/models/fork.dart';
import 'package:cantrip/models/prompt_folder.dart';
import 'package:cantrip/state/remote_user_data_api.dart';
import 'package:cantrip/state/synced_user_data_store.dart';
import 'package:cantrip/state/user_data_store.dart';

/// In-memory stand-ins. The point of the split between the sync rules and
/// the Supabase calls is that the rules can be tested like this.
class FakeLocalStore implements UserDataStore {
  UserData data;
  int writes = 0;

  FakeLocalStore([this.data = const UserData()]);

  @override
  Future<UserData> load() async => data;

  @override
  Future<void> saveFavourites(Set<String> ids) async {
    writes++;
    data = UserData(
      favouriteIds: ids,
      folders: data.folders,
      signals: data.signals,
    );
  }

  @override
  Future<void> saveFolders(List<PromptFolder> folders) async {
    writes++;
    data = UserData(
      favouriteIds: data.favouriteIds,
      folders: folders,
      signals: data.signals,
    );
  }

  @override
  Future<void> saveSignals(Map<String, bool> signals) async {
    writes++;
    data = UserData(
      favouriteIds: data.favouriteIds,
      folders: data.folders,
      signals: signals,
    );
  }

  @override
  Future<void> clear() async {
    writes++;
    data = const UserData();
  }
}

class FakeRemoteApi implements RemoteUserDataApi {
  @override
  String? currentUserId;

  UserData server = const UserData();
  bool throwOnEverything = false;
  int uploads = 0;

  FakeRemoteApi({this.currentUserId});

  void _check() {
    if (throwOnEverything) throw StateError('offline');
  }

  @override
  Future<UserData> fetch(String userId) async {
    _check();
    return server;
  }

  @override
  Future<void> replaceFavourites(String userId, Set<String> ids) async {
    _check();
    uploads++;
    server = UserData(
      favouriteIds: ids,
      folders: server.folders,
      signals: server.signals,
    );
  }

  @override
  Future<void> replaceFolders(String userId, List<PromptFolder> folders) async {
    _check();
    uploads++;
    server = UserData(
      favouriteIds: server.favouriteIds,
      folders: folders,
      signals: server.signals,
    );
  }

  @override
  Future<void> replaceSignals(String userId, Map<String, bool> signals) async {
    _check();
    uploads++;
    server = UserData(
      favouriteIds: server.favouriteIds,
      folders: server.folders,
      signals: signals,
    );
  }

  @override
  Future<void> deleteAll(String userId) async {
    _check();
    uploads++;
    server = const UserData();
  }
}

PromptFolder folderWith(String id, String name) => PromptFolder(
  id: id,
  name: name,
  type: FolderType.client,
  items: [
    Fork(
      id: '$id-fork',
      sourceVariantId: 'var_hgf_soulid',
      values: const {'character_name': 'Mira'},
      sourceVerifiedOn: DateTime(2026, 9, 2),
      createdAt: DateTime(2026, 9, 3),
    ),
  ],
);

void main() {
  group('sync', () {
    test('signed out, nothing reaches the server', () async {
      final local = FakeLocalStore(
        UserData(
          favouriteIds: const {'a'},
          folders: [folderWith('f1', 'Acme')],
        ),
      );
      final remote = FakeRemoteApi();
      final store = SyncedUserDataStore(local: local, remote: remote);

      final loaded = await store.load();
      await store.saveFavourites({'a', 'b'});

      expect(loaded.favouriteIds, {'a'});
      expect(remote.uploads, 0, reason: 'no account, no network writes');
      expect(local.data.favouriteIds, {'a', 'b'});
    });

    test('the first sign-in keeps what is already on the device', () async {
      final local = FakeLocalStore(
        UserData(
          favouriteIds: const {'var_hgf_soulid'},
          folders: [folderWith('f1', 'Acme')],
          signals: const {'var_hgf_soulid': true},
        ),
      );
      // A brand new account: signed in, but the server has nothing.
      final remote = FakeRemoteApi(currentUserId: 'user-1');
      final store = SyncedUserDataStore(local: local, remote: remote);

      final loaded = await store.load();

      expect(loaded.favouriteIds, {'var_hgf_soulid'});
      expect(loaded.folders.single.name, 'Acme');
      expect(remote.server.folders.single.items.single.values, {
        'character_name': 'Mira',
      });
      expect(remote.server.signals, {'var_hgf_soulid': true});
    });

    test('once the server has data it wins, and is cached locally', () async {
      final local = FakeLocalStore(
        UserData(
          favouriteIds: const {'stale'},
          folders: [folderWith('old', 'Stale folder')],
        ),
      );
      final remote = FakeRemoteApi(currentUserId: 'user-1')
        ..server = UserData(
          favouriteIds: const {'fresh'},
          folders: [folderWith('new', 'Real folder')],
        );
      final store = SyncedUserDataStore(local: local, remote: remote);

      final loaded = await store.load();

      expect(loaded.favouriteIds, {'fresh'});
      expect(loaded.folders.single.name, 'Real folder');
      // Cached, so the next cold start shows the synced data offline.
      expect(local.data.favouriteIds, {'fresh'});
      expect(local.data.folders.single.name, 'Real folder');
    });

    test('a failing server never loses a local write', () async {
      final local = FakeLocalStore(const UserData(favouriteIds: {'kept'}));
      final remote = FakeRemoteApi(currentUserId: 'user-1')
        ..throwOnEverything = true;
      final errors = <Object>[];
      final store = SyncedUserDataStore(
        local: local,
        remote: remote,
        onError: errors.add,
      );

      final loaded = await store.load();
      await store.saveFavourites({'kept', 'added'});

      // Load falls back to the cache, the save still lands on the device,
      // and the failure is reported rather than thrown at the user.
      expect(loaded.favouriteIds, {'kept'});
      expect(local.data.favouriteIds, {'kept', 'added'});
      expect(errors, hasLength(2));
    });
  });
}
