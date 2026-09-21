import 'package:flutter/foundation.dart';

import '../models/author_note.dart';
import '../models/freshness.dart';

/// Badges shown on a prompt.
///
/// Split deliberately by who is entitled to assert them. The author's own
/// badges are opinions with a name attached; the community ones are
/// arithmetic over real signals. Hand-setting a "popular" badge would be a
/// fabricated testimonial, so there is no code path that allows it.
enum PromptBadge { creatorsChoice, redFlag, popular, communityApproved }

extension PromptBadgeX on PromptBadge {
  String get label => switch (this) {
    PromptBadge.creatorsChoice => "Creator's pick",
    PromptBadge.redFlag => 'Read the note first',
    PromptBadge.popular => 'Popular',
    PromptBadge.communityApproved => 'Community approved',
  };

  /// Whether this is the author speaking or the users. Shown in the UI so
  /// a reader always knows whose claim they are looking at.
  bool get isAuthorOpinion =>
      this == PromptBadge.creatorsChoice || this == PromptBadge.redFlag;
}

/// Holds the author's notes and answers questions about them.
class AuthorNotesController extends ChangeNotifier {
  /// Minimum signals before a community badge can appear at all. Below
  /// this, a "popular" badge would be three people and a rounding error.
  static const minSignalsForBadge = 25;

  /// Persists a note. Null in a local-only build, where there is no author
  /// mode at all — the screens check [isAuthor] before offering it.
  final Future<void> Function(AuthorNote)? save;

  AuthorNotesController({this.save});

  final Map<String, AuthorNote> _notes = {};

  bool _isAuthor = false;
  bool get isAuthor => _isAuthor;

  AuthorNote? noteFor(String variantId) => _notes[variantId];

  void replaceAll(Iterable<AuthorNote> notes, {required bool isAuthor}) {
    _notes
      ..clear()
      ..addEntries([for (final n in notes) MapEntry(n.variantId, n)]);
    _isAuthor = isAuthor;
    notifyListeners();
  }

  void put(AuthorNote note) {
    _notes[note.variantId] = note;
    notifyListeners();
  }

  /// Badges a prompt has actually earned.
  ///
  /// Author badges come from the note. Community badges are computed from
  /// real counts and are simply absent until the numbers exist — which is
  /// the point: an empty badge row is honest, and a young library looks
  /// young rather than pretending otherwise.
  List<PromptBadge> badgesFor(String variantId, FreshnessSignals signals) {
    final note = _notes[variantId];
    return [
      if (note?.creatorsChoice == true) PromptBadge.creatorsChoice,
      if (note?.redFlag == true) PromptBadge.redFlag,
      if (signals.total >= minSignalsForBadge) ...[
        if (signals.works >= 100) PromptBadge.popular,
        if (signals.brokenRatio <= 0.05) PromptBadge.communityApproved,
      ],
    ];
  }

  /// What the author says about a model, if anything: true works, false
  /// fails, null never tried. Three states, because "we haven't tried it"
  /// is information and "it doesn't work" is a different claim.
  bool? modelVerdict(String variantId, String modelLabel) {
    final note = _notes[variantId];
    if (note == null) return null;
    if (note.worksOn.contains(modelLabel)) return true;
    if (note.failsOn.contains(modelLabel)) return false;
    return null;
  }
}
