import '../models/prompt_folder.dart';
import 'remote_user_data_api.dart';
import 'user_data_store.dart';

/// User data kept in sync with a backend, with the local store as a
/// write-through cache.
///
/// Three rules shape this class:
///
/// 1. **Local is always written first.** Every save hits the device before
///    it hits the network, so the app stays instant and keeps working on a
///    plane. The remote write is reported-but-not-thrown; sync failing is
///    not a reason to fail an action the user has already seen succeed.
/// 2. **Signed out means local only.** Browsing and saving work with no
///    account, exactly as before — this store simply passes through.
/// 3. **The first sign-in adopts whatever is on the device.** Someone who
///    saved twenty prompts anonymously and then signs in must not lose
///    them, so a first sync uploads local data rather than overwriting it
///    with an empty server. After that the server is the source of truth.
class SyncedUserDataStore implements UserDataStore {
  final UserDataStore local;
  final RemoteUserDataApi remote;

  /// Reported rather than thrown, so the UI can surface sync trouble
  /// without any single action failing over it.
  final void Function(Object error)? onError;

  SyncedUserDataStore({
    required this.local,
    required this.remote,
    this.onError,
  });

  @override
  Future<UserData> load() async {
    final cached = await local.load();
    final userId = remote.currentUserId;
    if (userId == null) return cached;

    try {
      final server = await remote.fetch(userId);

      // An account with nothing in it, on a device that has something,
      // means this is the first sign-in: keep what's on the device and
      // push it up.
      if (_isEmpty(server) && !_isEmpty(cached)) {
        await _pushAll(userId, cached);
        return cached;
      }

      await _cache(server);
      return server;
    } catch (error) {
      onError?.call(error);
      return cached;
    }
  }

  @override
  Future<void> saveFavourites(Set<String> ids) async {
    await local.saveFavourites(ids);
    await _withUser((userId) => remote.replaceFavourites(userId, ids));
  }

  @override
  Future<void> saveSignals(Map<String, bool> signals) async {
    await local.saveSignals(signals);
    await _withUser((userId) => remote.replaceSignals(userId, signals));
  }

  @override
  Future<void> saveFolders(List<PromptFolder> folders) async {
    await local.saveFolders(folders);
    await _withUser((userId) => remote.replaceFolders(userId, folders));
  }

  @override
  Future<void> clear() async {
    await local.clear();
    await _withUser(remote.deleteAll);
  }

  /// Pushes everything on the device up. Used on first sign-in, and safe to
  /// repeat: each call replaces that user's rows.
  Future<void> _pushAll(String userId, UserData data) async {
    await remote.replaceFavourites(userId, data.favouriteIds);
    await remote.replaceSignals(userId, data.signals);
    await remote.replaceFolders(userId, data.folders);
  }

  Future<void> _cache(UserData data) async {
    await local.saveFavourites(data.favouriteIds);
    await local.saveSignals(data.signals);
    await local.saveFolders(data.folders);
  }

  Future<void> _withUser(Future<void> Function(String userId) action) async {
    final userId = remote.currentUserId;
    if (userId == null) return;
    try {
      await action(userId);
    } catch (error) {
      onError?.call(error);
    }
  }

  static bool _isEmpty(UserData data) =>
      data.favouriteIds.isEmpty && data.folders.isEmpty && data.signals.isEmpty;
}
