import 'freshness.dart';
import 'gallery_asset.dart';
import 'prompt_step.dart';
import 'prompt_variable.dart';

class Ownership {
  final String authorId;
  final String visibility; // public | private | workspace
  final String? forkedFromVariantId;
  final String? workspaceId;

  const Ownership({
    this.authorId = 'library',
    this.visibility = 'public',
    this.forkedFromVariantId,
    this.workspaceId,
  });
}

class VariantStats {
  final int copies;
  final int forks;

  const VariantStats({this.copies = 0, this.forks = 0});
}

/// One tool's answer to a [Goal].
///
/// Everything tool-specific lives here: native prompt syntax, the tool's own
/// parameter names, its model label, how many steps the workflow takes, and
/// what it requires as input. Two variants of the same goal can differ in
/// all of those and still be the same goal.
class PromptVariant {
  final String id;
  final String goalId;

  /// Null means no tool is preselected — a tool-agnostic recipe whose steps
  /// each carry their own tool or suggestions.
  final String? toolId;

  /// The tool's own version surface at time of writing. Empty string for
  /// tools that expose none.
  final String modelLabel;

  final String inputMethodId;
  final String title;
  final String summary;

  final List<PromptVariable> variables;
  final List<PromptStep> steps;

  /// Assets the author bundled (what they used) — distinct from image
  /// variables, which are what the user supplies.
  final List<GalleryAsset> bundledAssets;

  /// Before/after proof.
  final List<GalleryAsset> gallery;

  final Freshness freshness;
  final Ownership ownership;
  final VariantStats stats;

  const PromptVariant({
    required this.id,
    required this.goalId,
    this.toolId,
    this.modelLabel = '',
    required this.inputMethodId,
    required this.title,
    required this.summary,
    this.variables = const [],
    required this.steps,
    this.bundledAssets = const [],
    this.gallery = const [],
    required this.freshness,
    this.ownership = const Ownership(),
    this.stats = const VariantStats(),
  });

  bool get isRecipe => steps.length > 1;

  List<GalleryAsset> get beforeAssets =>
      gallery.where((a) => a.kind == AssetKind.before).toList();

  List<GalleryAsset> get afterAssets =>
      gallery.where((a) => a.kind == AssetKind.after).toList();

  /// Every tool this variant touches, in step order. A recipe may cross
  /// tools, so this is not just [toolId].
  List<String> get involvedToolIds {
    final seen = <String>[];
    for (final s in steps) {
      final id = s.toolId;
      if (id != null && !seen.contains(id)) seen.add(id);
    }
    return seen;
  }

  PromptVariable? variableByKey(String key) {
    for (final v in variables) {
      if (v.key == key) return v;
    }
    return null;
  }

  /// Default values for every variable, used to seed the live preview so it
  /// is never shown empty.
  Map<String, String> initialValues() => {
    for (final v in variables) v.key: v.initialValue,
  };

  /// Fills `{{key}}` placeholders from [values], falling back to a
  /// variable's default and then to the raw token so a half-filled preview
  /// still shows what is missing.
  String render(String template, Map<String, String> values) {
    var out = template;
    for (final v in variables) {
      final entered = values[v.key]?.trim() ?? '';
      final fallback = v.initialValue.isNotEmpty
          ? v.initialValue
          : '{{${v.key}}}';
      out = out.replaceAll(
        '{{${v.key}}}',
        entered.isNotEmpty ? entered : fallback,
      );
    }
    return out;
  }

  /// Moves what the user already typed from one variant to another when
  /// they switch tools.
  ///
  /// Values travel by [PromptVariable.bindsTo] — the goal's shared contract
  /// key — not by variable name, because the tool-native names differ
  /// (Higgsfield calls it a character name, OpenArt calls it a trigger
  /// word). Anything with no counterpart in [to] is simply not carried; the
  /// caller keeps the old map so switching back restores it.
  static Map<String, String> carryValues({
    required PromptVariant from,
    required PromptVariant to,
    required Map<String, String> values,
  }) {
    final byContractKey = <String, String>{};
    for (final v in from.variables) {
      final contractKey = v.bindsTo;
      final value = values[v.key];
      if (contractKey != null && value != null && value.trim().isNotEmpty) {
        byContractKey[contractKey] = value;
      }
    }

    final carried = to.initialValues();
    for (final v in to.variables) {
      final contractKey = v.bindsTo;
      if (contractKey == null) continue;
      final inherited = byContractKey[contractKey];
      if (inherited != null) carried[v.key] = inherited;
    }
    return carried;
  }

  PromptVariant copyWith({
    String? id,
    String? title,
    List<PromptStep>? steps,
    List<PromptVariable>? variables,
    Ownership? ownership,
  }) {
    return PromptVariant(
      id: id ?? this.id,
      goalId: goalId,
      toolId: toolId,
      modelLabel: modelLabel,
      inputMethodId: inputMethodId,
      title: title ?? this.title,
      summary: summary,
      variables: variables ?? this.variables,
      steps: steps ?? this.steps,
      bundledAssets: bundledAssets,
      gallery: gallery,
      freshness: freshness,
      ownership: ownership ?? this.ownership,
      stats: stats,
    );
  }
}
