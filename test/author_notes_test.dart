import 'package:flutter_test/flutter_test.dart';
import 'package:cantrip/models/author_note.dart';
import 'package:cantrip/models/freshness.dart';
import 'package:cantrip/state/author_notes_controller.dart';

AuthorNote note({
  String id = 'var_x',
  DateTime? testedOn,
  AuthorVerdict verdict = AuthorVerdict.works,
  List<String> worksOn = const [],
  List<String> failsOn = const [],
  bool creatorsChoice = false,
  bool redFlag = false,
}) => AuthorNote(
  variantId: id,
  testedOn: testedOn,
  verdict: verdict,
  worksOn: worksOn,
  failsOn: failsOn,
  creatorsChoice: creatorsChoice,
  redFlag: redFlag,
  updatedAt: DateTime(2026, 9, 21),
);

void main() {
  group('author verification', () {
    test('a verdict without a date is an opinion, not a verification', () {
      // The date is what makes it a verification rather than a belief, so
      // the badge must not light up without one.
      expect(note(verdict: AuthorVerdict.works).isVerified, isFalse);
      expect(
        note(
          verdict: AuthorVerdict.works,
          testedOn: DateTime(2026, 9, 21),
        ).isVerified,
        isTrue,
      );
    });

    test('a broken verdict is never "verified", dated or not', () {
      expect(
        note(
          verdict: AuthorVerdict.broken,
          testedOn: DateTime(2026, 9, 21),
        ).isVerified,
        isFalse,
      );
    });

    test('works-on and fails-on survive a round trip', () {
      final original = note(
        testedOn: DateTime(2026, 9, 21),
        worksOn: ['v6.1'],
        failsOn: ['v7'],
      );
      final restored = AuthorNote.fromJson({
        ...original.toJson(),
        'updated_at': '2026-09-21T00:00:00Z',
      });

      expect(restored!.worksOn, ['v6.1']);
      expect(restored.failsOn, ['v7']);
      expect(restored.testedOn, DateTime(2026, 9, 21));
    });

    test('a model verdict has three states, not two', () {
      final controller = AuthorNotesController();
      controller.replaceAll([
        note(worksOn: ['v6.1'], failsOn: ['v7']),
      ], isAuthor: true);

      expect(controller.modelVerdict('var_x', 'v6.1'), isTrue);
      expect(controller.modelVerdict('var_x', 'v7'), isFalse);
      // Never tried is information, and is not the same as "doesn't work".
      expect(controller.modelVerdict('var_x', 'v6'), isNull);
    });
  });

  group('badges', () {
    test('the author can set their own opinions', () {
      final controller = AuthorNotesController();
      controller.replaceAll([
        note(creatorsChoice: true, redFlag: true),
      ], isAuthor: true);

      final badges = controller.badgesFor('var_x', const FreshnessSignals());
      expect(badges, contains(PromptBadge.creatorsChoice));
      expect(badges, contains(PromptBadge.redFlag));
      // And they are labelled as the author's, not as consensus.
      expect(PromptBadge.creatorsChoice.isAuthorOpinion, isTrue);
      expect(PromptBadge.popular.isAuthorOpinion, isFalse);
    });

    test('community badges cannot be set by hand, only earned', () {
      final controller = AuthorNotesController();
      // An author note claiming everything, on a prompt with no signals.
      controller.replaceAll([note(creatorsChoice: true)], isAuthor: true);

      final badges = controller.badgesFor('var_x', const FreshnessSignals());
      expect(
        badges,
        isNot(contains(PromptBadge.popular)),
        reason: 'a hand-set popularity badge is a fabricated testimonial',
      );
      expect(badges, isNot(contains(PromptBadge.communityApproved)));
    });

    test('a young library shows no community badges at all', () {
      final controller = AuthorNotesController();
      controller.replaceAll(const [], isAuthor: false);

      // Below the threshold, even a perfect record earns nothing: three
      // people and a rounding error is not popularity.
      final young = controller.badgesFor(
        'var_x',
        const FreshnessSignals(works: 24, broken: 0),
      );
      expect(young, isEmpty);

      final earned = controller.badgesFor(
        'var_x',
        const FreshnessSignals(works: 120, broken: 2),
      );
      expect(earned, contains(PromptBadge.popular));
      expect(earned, contains(PromptBadge.communityApproved));
    });

    test('a prompt people report broken is not community approved', () {
      final controller = AuthorNotesController();
      controller.replaceAll(const [], isAuthor: false);

      final badges = controller.badgesFor(
        'var_x',
        const FreshnessSignals(works: 100, broken: 30),
      );
      expect(badges, contains(PromptBadge.popular));
      expect(badges, isNot(contains(PromptBadge.communityApproved)));
    });
  });
}
