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

/// Local persistence for user data.
///
/// Deliberately not a backend. The library itself ships in the app bundle,
/// so the only thing worth storing is what the user did: saved prompts,
/// folders and their reports. Writing that to local storage takes the app
/// from "forgets everything on restart" to genuinely reusable, with no
/// account, no server and no cost — and it is the same shape the Supabase
/// tables will take, so sync later is a second implementation of this
/// interface rather than a rewrite.
///
/// Every read is defensive: storage can be cleared, corrupted, or written
/// by an older version of the app, and none of that should stop it opening.
class UserDataStore {
  static const _favouritesKey = 'pc.favourites.v1';
  static const _foldersKey = 'pc.folders.v1';
  static const _signalsKey = 'pc.signals.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

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

  Future<void> saveFavourites(Set<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(_favouritesKey, ids.toList());
  }

  Future<void> saveFolders(List<PromptFolder> folders) async {
    final prefs = await _prefs;
    await prefs.setString(
      _foldersKey,
      jsonEncode([for (final f in folders) f.toJson()]),
    );
  }

  Future<void> saveSignals(Map<String, bool> signals) async {
    final prefs = await _prefs;
    await prefs.setString(_signalsKey, jsonEncode(signals));
  }

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
