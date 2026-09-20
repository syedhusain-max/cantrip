import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/prompt_folder.dart';

/// Everything the user owns, as it is written to disk.
class UserData {
  final Set<String> favouriteIds;
  final List<PromptFolder> folders;

  /// variantId → true if the user said it works, false if broken.
  final Map<String, bool> signals;

  const UserData({
    this.favouriteIds = const {},
    this.folders = const [],
    this.signals = const {},
  });
}

/// Where user data is read from and written to.
///
/// The library itself ships in the app bundle, so the only thing worth
/// storing is what the user did: saved prompts, folders and their reports.
/// [LocalUserDataStore] keeps that on the device; [SyncedUserDataStore]
/// keeps the same shape in Supabase once the user signs in. Nothing above
/// this interface knows which one it has.
abstract interface class UserDataStore {
  Future<UserData> load();
  Future<void> saveFavourites(Set<String> ids);
  Future<void> saveFolders(List<PromptFolder> folders);
  Future<void> saveSignals(Map<String, bool> signals);
  Future<void> clear();
}

/// On-device persistence, and the offline cache the synced store writes
/// through to. No account, no server, no cost.
///
/// Every read is defensive: storage can be cleared, corrupted, or written
/// by an older version of the app, and none of that should stop it opening.
class LocalUserDataStore implements UserDataStore {
  static const _favouritesKey = 'pc.favourites.v1';
  static const _foldersKey = 'pc.folders.v1';
  static const _signalsKey = 'pc.signals.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<UserData> load() async {
    try {
      final prefs = await _prefs;
      return UserData(
        favouriteIds: (prefs.getStringList(_favouritesKey) ?? const []).toSet(),
        folders: _decodeFolders(prefs.getString(_foldersKey)),
        signals: _decodeSignals(prefs.getString(_signalsKey)),
      );
    } catch (_) {
      // A failed read must never block startup — the user just sees an
      // empty Saved tab rather than a crash.
      return const UserData();
    }
  }

  @override
  Future<void> saveFavourites(Set<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(_favouritesKey, ids.toList());
  }

  @override
  Future<void> saveFolders(List<PromptFolder> folders) async {
    final prefs = await _prefs;
    await prefs.setString(
      _foldersKey,
      jsonEncode([for (final f in folders) f.toJson()]),
    );
  }

  @override
  Future<void> saveSignals(Map<String, bool> signals) async {
    final prefs = await _prefs;
    await prefs.setString(_signalsKey, jsonEncode(signals));
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_favouritesKey);
    await prefs.remove(_foldersKey);
    await prefs.remove(_signalsKey);
  }

  List<PromptFolder> _decodeFolders(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final entry in decoded)
          if (entry is Map<String, dynamic>) ?PromptFolder.fromJson(entry),
      ];
    } catch (_) {
      return [];
    }
  }

  Map<String, bool> _decodeSignals(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if (e.value is bool) '${e.key}': e.value as bool,
      };
    } catch (_) {
      return {};
    }
  }
}
