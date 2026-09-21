/// The author's own record of testing a prompt.
///
/// Kept separate from [Freshness] because they answer different questions.
/// Freshness is what the *library* claims and how it decays; this is what
/// the person who ran it says, with their name on it. Overrides are stored
/// server-side rather than in the bundle, so marking a prompt verified
/// changes the live app immediately — which matters when freshness is the
/// product.
class AuthorNote {
  final String variantId;

  /// The day it was actually run. Null means never run by the author, which
  /// is a different and more honest state than "verified long ago".
  final DateTime? testedOn;

  /// The model it was run against, as the tool labels it.
  final String? testedModelLabel;

  /// Models the author has confirmed work, and ones confirmed not to.
  /// Kept as two lists rather than a pass/fail flag because "works on
  /// v6.1, fails on v7" is the single most useful thing to know about a
  /// prompt and has nowhere else to live.
  final List<String> worksOn;
  final List<String> failsOn;

  /// Where the author got the best result, when it differs from the
  /// variant's own tool — e.g. a prompt that is fine in Midjourney and
  /// better in OpenArt.
  final String? bestInToolId;

  /// The author's verdict.
  final AuthorVerdict verdict;

  /// Free text: what was observed, what broke, what to watch for.
  final String? note;

  /// The author's editorial pick. Clearly their opinion, never presented as
  /// a community verdict.
  final bool creatorsChoice;

  /// The author's warning flag: still published, but read the note first.
  final bool redFlag;

  final DateTime updatedAt;

  const AuthorNote({
    required this.variantId,
    this.testedOn,
    this.testedModelLabel,
    this.worksOn = const [],
    this.failsOn = const [],
    this.bestInToolId,
    this.verdict = AuthorVerdict.untested,
    this.note,
    this.creatorsChoice = false,
    this.redFlag = false,
    required this.updatedAt,
  });

  /// True when the author has actually run it. A verdict without a date is
  /// an opinion, not a verification, and the UI says so.
  bool get isVerified => verdict == AuthorVerdict.works && testedOn != null;

  Map<String, dynamic> toJson() => {
    'variant_id': variantId,
    'tested_on': testedOn?.toIso8601String().split('T').first,
    'tested_model_label': testedModelLabel,
    'works_on': worksOn,
    'fails_on': failsOn,
    'best_in_tool_id': bestInToolId,
    'verdict': verdict.name,
    'note': note,
    'creators_choice': creatorsChoice,
    'red_flag': redFlag,
  };

  static AuthorNote? fromJson(Map<String, dynamic> json) {
    final variantId = json['variant_id'];
    if (variantId is! String) return null;
    return AuthorNote(
      variantId: variantId,
      testedOn: DateTime.tryParse('${json['tested_on']}'),
      testedModelLabel: json['tested_model_label'] as String?,
      worksOn: [for (final v in (json['works_on'] as List? ?? [])) '$v'],
      failsOn: [for (final v in (json['fails_on'] as List? ?? [])) '$v'],
      bestInToolId: json['best_in_tool_id'] as String?,
      verdict: AuthorVerdict.values.firstWhere(
        (v) => v.name == json['verdict'],
        orElse: () => AuthorVerdict.untested,
      ),
      note: json['note'] as String?,
      creatorsChoice: json['creators_choice'] == true,
      redFlag: json['red_flag'] == true,
      updatedAt: DateTime.tryParse('${json['updated_at']}') ?? DateTime.now(),
    );
  }
}

enum AuthorVerdict {
  /// Never run by the author. The honest default.
  untested,

  /// Ran it, got what the prompt promises.
  works,

  /// Ran it, it did not work.
  broken,

  /// Ran it, it worked but with caveats worth reading.
  worksWithCaveats,
}

extension AuthorVerdictX on AuthorVerdict {
  String get label => switch (this) {
    AuthorVerdict.untested => 'Not yet tested',
    AuthorVerdict.works => 'Verified working',
    AuthorVerdict.broken => 'Author found it broken',
    AuthorVerdict.worksWithCaveats => 'Works, with caveats',
  };
}
