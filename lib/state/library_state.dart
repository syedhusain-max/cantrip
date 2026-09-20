import 'package:flutter/foundation.dart';

import '../data/sample_library.dart';
import '../data/taxonomy_registry.dart';
import '../models/fork.dart';
import '../models/freshness.dart';
import '../models/goal.dart';
import '../models/prompt_folder.dart';
import '../models/prompt_variable.dart';
import '../models/prompt_variant.dart';
import 'user_data_store.dart';

/// Active search and filter criteria across the five independent axes.
class LibraryFilter {
  final String search;
  final String? toolId;
  final String? useCaseId;
  final String? nicheId;
  final String? outputTypeId;
  final String? inputMethodId;

  const LibraryFilter({
    this.search = '',
    this.toolId,
    this.useCaseId,
    this.nicheId,
    this.outputTypeId,
    this.inputMethodId,
  });

  bool get isEmpty =>
      search.isEmpty &&
      toolId == null &&
      useCaseId == null &&
      nicheId == null &&
      outputTypeId == null &&
      inputMethodId == null;

  int get activeCount => [
    toolId,
    useCaseId,
    nicheId,
    outputTypeId,
    inputMethodId,
  ].where((v) => v != null).length;

  /// Query-string form, so a filtered library view is a shareable URL.
  /// Only non-empty axes are emitted, keeping `/library` clean when nothing
  /// is set.
  Map<String, String> toQueryParameters() => {
    if (search.isNotEmpty) 'q': search,
    'tool': ?toolId,
    'useCase': ?useCaseId,
    'niche': ?nicheId,
    'output': ?outputTypeId,
    'input': ?inputMethodId,
  };

  factory LibraryFilter.fromQueryParameters(Map<String, String> params) {
    return LibraryFilter(
      search: params['q'] ?? '',
      toolId: params['tool'],
      useCaseId: params['useCase'],
      nicheId: params['niche'],
      outputTypeId: params['output'],
      inputMethodId: params['input'],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LibraryFilter &&
      other.search == search &&
      other.toolId == toolId &&
      other.useCaseId == useCaseId &&
      other.outputTypeId == outputTypeId &&
      other.nicheId == nicheId &&
      other.inputMethodId == inputMethodId;

  @override
  int get hashCode => Object.hash(
    search,
    toolId,
    useCaseId,
    nicheId,
    outputTypeId,
    inputMethodId,
  );

  LibraryFilter copyWith({
    String? search,
    String? toolId,
    bool clearTool = false,
    String? useCaseId,
    bool clearUseCase = false,
    String? nicheId,
    bool clearNiche = false,
    String? outputTypeId,
    bool clearOutputType = false,
    String? inputMethodId,
    bool clearInputMethod = false,
  }) {
    return LibraryFilter(
      search: search ?? this.search,
      toolId: clearTool ? null : (toolId ?? this.toolId),
      useCaseId: clearUseCase ? null : (useCaseId ?? this.useCaseId),
      nicheId: clearNiche ? null : (nicheId ?? this.nicheId),
      outputTypeId: clearOutputType
          ? null
          : (outputTypeId ?? this.outputTypeId),
      inputMethodId: clearInputMethod
          ? null
          : (inputMethodId ?? this.inputMethodId),
    );
  }
}

/// A variant paired with the goal it serves — what list rows actually need,
/// since the title and classification live on the goal and the tool-specific
/// detail lives on the variant.
class LibraryItem {
  final Goal goal;
  final PromptVariant variant;

  const LibraryItem({required this.goal, required this.variant});

  String get id => variant.id;
}

/// Owns the seeded library plus the user's own data.
///
/// The library ships in the app bundle; only what the user does is stored,
/// via [UserDataStore]. Passing no store (as tests do) keeps everything in
/// memory. The shape here matches what the Supabase tables will hold, so
/// adding sync later is a second store implementation rather than a
/// rewrite of the screens.
class LibraryState extends ChangeNotifier {
  LibraryState({DateTime? now, this.store}) : _now = now ?? DateTime.now() {
    for (final g in sampleGoals) {
      _goalsById[g.id] = g;
    }
    _variants.addAll(sampleVariants);
  }

  final DateTime _now;

  /// Where user data is persisted. Null keeps everything in memory (tests).
  final UserDataStore? store;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Reads saved user data. Safe to call once at startup; without a store
  /// it completes immediately and the app runs in-memory.
  Future<void> load() async {
    if (store == null) {
      _loaded = true;
      return;
    }
    final data = await store!.load();
    // Cleared because load() runs again after a sign-in, when the data
    // underneath it has changed: stale overrides would show the previous
    // account's votes.
    _signalOverrides.clear();
    _favouriteIds
      ..clear()
      ..addAll(data.favouriteIds);
    _folders
      ..clear()
      ..addAll(data.folders);
    _mySignals
      ..clear()
      ..addAll(data.signals);
    // Replay the user's own reports so their vote is reflected in the
    // counts they see, not just remembered silently.
    for (final entry in data.signals.entries) {
      final variant = variantById(entry.key);
      if (variant == null) continue;
      final base = variant.freshness.signals;
      _signalOverrides[entry.key] = base.copyWith(
        works: entry.value ? base.works + 1 : base.works,
        broken: entry.value ? base.broken : base.broken + 1,
      );
    }
    _loaded = true;
    notifyListeners();
  }

  final Map<String, Goal> _goalsById = {};
  final List<PromptVariant> _variants = [];

  final Set<String> _favouriteIds = {};
  final List<PromptFolder> _folders = [];

  /// Signals the current user has submitted, so the UI can show what they
  /// reported and prevent double-voting.
  final Map<String, bool> _mySignals = {};

  /// Signal counts layered on top of the seeded ones.
  final Map<String, FreshnessSignals> _signalOverrides = {};

  DateTime get now => _now;

  List<Goal> get goals => List.unmodifiable(_goalsById.values);

  List<PromptFolder> get folders => List.unmodifiable(_folders);

  Goal? goalById(String id) => _goalsById[id];

  PromptVariant? variantById(String id) {
    for (final v in _variants) {
      if (v.id == id) return v;
    }
    return null;
  }

  LibraryItem? itemById(String variantId) {
    final v = variantById(variantId);
    if (v == null) return null;
    final g = _goalsById[v.goalId];
    if (g == null) return null;
    return LibraryItem(goal: g, variant: v);
  }

  /// Every variant paired with its goal, skipping any orphan whose goal is
  /// missing rather than throwing on bad data.
  List<LibraryItem> get allItems => [
    for (final v in _variants)
      if (_goalsById[v.goalId] != null)
        LibraryItem(goal: _goalsById[v.goalId]!, variant: v),
  ];

  // ---------------------------------------------------------------- freshness

  FreshnessSignals signalsFor(PromptVariant v) =>
      _signalOverrides[v.id] ?? v.freshness.signals;

  FreshnessStatus statusFor(PromptVariant v) =>
      v.freshness.copyWith(signals: signalsFor(v)).statusAt(_now);

  /// What the current user reported for this variant: true = works,
  /// false = broken, null = no report yet.
  bool? mySignal(String variantId) => _mySignals[variantId];

  /// Records a "still works" or "broken" report.
  ///
  /// This is the only community feature in Phase 1. It is deliberately
  /// binary: with one author and few users, a star average computed from a
  /// handful of votes is noise, while "does this still work" maps directly
  /// to the real failure mode of a tool update.
  void submitSignal(String variantId, {required bool works}) {
    final variant = variantById(variantId);
    if (variant == null) return;

    final current = signalsFor(variant);
    final previous = _mySignals[variantId];
    if (previous == works) return;

    var worksCount = current.works;
    var brokenCount = current.broken;

    // Withdraw an earlier opposite vote so a user can correct themselves
    // without inflating the totals.
    if (previous == true) worksCount = (worksCount - 1).clamp(0, 1 << 30);
    if (previous == false) brokenCount = (brokenCount - 1).clamp(0, 1 << 30);

    if (works) {
      worksCount += 1;
    } else {
      brokenCount += 1;
    }

    _signalOverrides[variantId] = current.copyWith(
      works: worksCount,
      broken: brokenCount,
      lastBrokenReport: works ? current.lastBrokenReport : _now,
    );
    _mySignals[variantId] = works;
    store?.saveSignals(_mySignals);
    notifyListeners();
  }

  // ---------------------------------------------------------------- variants

  /// Other variants serving the same goal — the tool switcher's options.
  List<LibraryItem> variantsForGoal(String goalId, {String? excludeVariantId}) {
    final goal = _goalsById[goalId];
    if (goal == null) return const [];
    return [
      for (final v in _variants)
        if (v.goalId == goalId && v.id != excludeVariantId)
          LibraryItem(goal: goal, variant: v),
    ];
  }

  // ---------------------------------------------------------------- filtering

  List<LibraryItem> filtered(LibraryFilter filter) {
    final results = allItems.where((item) {
      final g = item.goal;
      final v = item.variant;

      if (filter.toolId != null) {
        final matchesTool =
            v.toolId == filter.toolId ||
            v.involvedToolIds.contains(filter.toolId);
        if (!matchesTool) return false;
      }
      if (filter.useCaseId != null && g.useCaseId != filter.useCaseId) {
        return false;
      }
      if (filter.nicheId != null && !g.nicheIds.contains(filter.nicheId)) {
        return false;
      }
      if (filter.outputTypeId != null &&
          g.outputTypeId != filter.outputTypeId) {
        return false;
      }
      if (filter.inputMethodId != null &&
          v.inputMethodId != filter.inputMethodId) {
        return false;
      }

      if (filter.search.trim().isNotEmpty) {
        final q = filter.search.toLowerCase();
        final haystack = [
          v.title,
          v.summary,
          g.title,
          g.summary,
          useCaseLabel(g.useCaseId),
          outputTypeLabel(g.outputTypeId),
          for (final n in g.nicheIds) nicheLabel(n),
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();

    // Broken and stale prompts sink below healthy ones rather than being
    // hidden, so a user can still find and re-verify them.
    results.sort((a, b) {
      final aDemoted = statusFor(a.variant).demoteInSearch ? 1 : 0;
      final bDemoted = statusFor(b.variant).demoteInSearch ? 1 : 0;
      if (aDemoted != bDemoted) return aDemoted - bDemoted;
      return b.variant.freshness.verifiedOn.compareTo(
        a.variant.freshness.verifiedOn,
      );
    });
    return results;
  }

  // -------------------------------------------------------------- favourites

  List<LibraryItem> get favourites =>
      allItems.where((i) => _favouriteIds.contains(i.variant.id)).toList();

  bool isFavourite(String variantId) => _favouriteIds.contains(variantId);

  void toggleFavourite(String variantId) {
    if (!_favouriteIds.add(variantId)) _favouriteIds.remove(variantId);
    store?.saveFavourites(_favouriteIds);
    notifyListeners();
  }

  // ------------------------------------------------------------------ folders

  /// Category ids that actually have prompts behind them.
  ///
  /// A browse tile that leads to an empty list is worse than a missing
  /// tile: it reads as a broken app rather than a young one. The registry
  /// still defines every category — this only decides what to *show*, so
  /// seeding a category later makes its tile appear with no code change.
  Set<String> get populatedUseCaseIds => {
    for (final item in allItems) item.goal.useCaseId,
  };

  Set<String> get populatedOutputTypeIds => {
    for (final item in allItems) item.goal.outputTypeId,
  };

  Set<String> get populatedToolIds => {
    for (final item in allItems)
      if (item.variant.toolId != null) item.variant.toolId!,
    // A recipe can cross tools, so a tool can be present only in a step.
    for (final item in allItems)
      for (final step in item.variant.steps)
        if (step.toolId != null) step.toolId!,
  };

  /// Every saved copy across every folder — what the saved-copy limit
  /// counts, since folders are a grouping, not a quota boundary.
  int get savedCopyCount =>
      _folders.fold(0, (total, folder) => total + folder.items.length);

  PromptFolder createFolder(String name, FolderType type) {
    final folder = PromptFolder(
      id: 'folder-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: type,
    );
    _folders.add(folder);
    _persistFolders();
    notifyListeners();
    return folder;
  }

  void deleteFolder(String id) {
    _folders.removeWhere((f) => f.id == id);
    _persistFolders();
    notifyListeners();
  }

  PromptFolder? folderById(String id) {
    for (final f in _folders) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Saves a copy of a variant into a folder.
  Fork? forkToFolder(
    PromptVariant variant,
    String folderId, {
    Map<String, String>? values,
  }) {
    final folder = folderById(folderId);
    if (folder == null) return null;
    final fork = Fork(
      id: 'fork-${DateTime.now().microsecondsSinceEpoch}',
      sourceVariantId: variant.id,
      values: values == null ? {} : Map.of(values),
      sourceVerifiedOn: variant.freshness.verifiedOn,
      createdAt: _now,
    );
    folder.items.add(fork);
    _persistFolders();
    notifyListeners();
    return fork;
  }

  Fork? forkById(String folderId, String forkId) {
    for (final f in folderById(folderId)?.items ?? const <Fork>[]) {
      if (f.id == forkId) return f;
    }
    return null;
  }

  /// The library variant a saved copy points at, or null if it has since
  /// been removed from the library.
  PromptVariant? sourceOf(Fork fork) => variantById(fork.sourceVariantId);

  /// True when the library prompt has been re-verified since this copy was
  /// saved — the user may want to pull in the newer version.
  bool hasUpstreamUpdate(Fork fork) {
    final source = sourceOf(fork);
    if (source == null) return false;
    return source.freshness.verifiedOn.isAfter(fork.sourceVerifiedOn);
  }

  /// Saved copies whose source prompt has since been reported broken, or
  /// has vanished from the library entirely.
  ///
  /// This is the in-app half of the "told when a prompt you saved stops
  /// working" promise: no push notification, no server job — the library
  /// already knows a prompt's status, and a saved copy already knows which
  /// prompt it came from. The alert is just asking the question.
  List<({PromptFolder folder, Fork fork, bool missing})>
  get savedCopiesNeedingAttention => [
    for (final folder in _folders)
      for (final fork in folder.items)
        if (variantById(fork.sourceVariantId) case final source?)
          if (statusFor(source) == FreshnessStatus.broken)
            (folder: folder, fork: fork, missing: false)
          else
            ...[]
        else
          (folder: folder, fork: fork, missing: true),
  ];

  /// Sets or clears one folder-level default.
  ///
  /// Keyed by the *goal contract* key, not by a tool's variable name, so a
  /// brand colour set once applies to every prompt saved into the folder
  /// regardless of which tool it targets. That is the whole point of the
  /// feature and the reason the contract exists.
  void setFolderDefault(String folderId, String contractKey, String value) {
    final folder = folderById(folderId);
    if (folder == null) return;
    if (value.trim().isEmpty) {
      folder.variableDefaults.remove(contractKey);
    } else {
      folder.variableDefaults[contractKey] = value.trim();
    }
    _persistFolders();
    notifyListeners();
  }

  /// Contract keys worth offering as folder defaults: the ones that appear
  /// on the goals behind prompts already saved in this folder. Offering the
  /// whole taxonomy would be a wall of fields that mostly do nothing.
  List<ContractField> defaultableFieldsFor(String folderId) {
    final folder = folderById(folderId);
    if (folder == null) return const [];

    final seen = <String, ContractField>{};
    for (final fork in folder.items) {
      final variant = variantById(fork.sourceVariantId);
      if (variant == null) continue;
      final goal = _goalsById[variant.goalId];
      if (goal == null) continue;
      for (final field in goal.inputContract) {
        // Only fields a variant actually binds to are useful as defaults —
        // an unbound contract key would set a value nothing reads.
        final isBound = variant.variables.any((v) => v.bindsTo == field.key);
        if (isBound) seen.putIfAbsent(field.key, () => field);
      }
    }
    return seen.values.toList();
  }

  void renameFork(String folderId, String forkId, String newTitle) {
    final fork = forkById(folderId, forkId);
    if (fork == null) return;
    fork.title = newTitle;
    _persistFolders();
    notifyListeners();
  }

  /// Stores the values a user filled in, so reopening a client's saved
  /// prompt comes back already filled with that client's details.
  void saveForkValues(
    String folderId,
    String forkId,
    Map<String, String> values,
  ) {
    final fork = forkById(folderId, forkId);
    if (fork == null) return;
    fork.values
      ..clear()
      ..addAll(values);
    _persistFolders();
    notifyListeners();
  }

  void removeFromFolder(String folderId, String forkId) {
    folderById(folderId)?.items.removeWhere((f) => f.id == forkId);
    _persistFolders();
    notifyListeners();
  }

  void _persistFolders() => store?.saveFolders(_folders);
}
