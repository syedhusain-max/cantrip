import 'package:flutter_test/flutter_test.dart';
import 'package:cantrip/data/draft_library.dart';
import 'package:cantrip/data/sample_library.dart';
import 'package:cantrip/data/taxonomy_registry.dart';
import 'package:cantrip/data/tool_registry.dart';
import 'package:cantrip/models/prompt_step.dart';

final _flag = RegExp(r'(?<![\w-])--[a-zA-Z][a-zA-Z0-9-]*');
final _token = RegExp(r'\{\{\s*([a-zA-Z0-9_]+)\s*\}\}');

Iterable<String> _templatesOf(DraftVariant v) sync* {
  for (final step in v.steps) {
    if (step.prompt != null) yield step.prompt!;
    if (step.negativePrompt != null) yield step.negativePrompt!;
    yield* step.settings.values;
  }
}

void main() {
  group('drafts stay out of the library', () {
    test('no draft has leaked into what ships', () {
      // The whole point of the split. A draft carries no verification date
      // because nobody ran it; if one reached the app it would appear
      // beside verified prompts with nothing to distinguish it.
      final shipped = {for (final v in sampleVariants) v.id};
      for (final draft in draftVariants) {
        expect(
          shipped,
          isNot(contains(draft.id)),
          reason:
              '${draft.id} is in the shipped library but has never been run. '
              'Promoting a draft means verifying it — see '
              'docs/verification-checklist.md',
        );
      }
    });

    test('a draft cannot claim to be verified', () {
      // Structural, not a convention: DraftVariant has no Freshness field,
      // so there is nowhere to put a date. This asserts the type still
      // works that way after any refactor.
      for (final draft in draftVariants) {
        expect(
          draft.toVerify,
          isNotEmpty,
          reason: '${draft.id} must say what still needs checking',
        );
        expect(
          draft.researchSource,
          startsWith('http'),
          reason: '${draft.id} must cite where its syntax came from',
        );
      }
    });
  });

  group('drafts are already correct where they can be checked', () {
    test('every flag is valid for the model the draft declares', () {
      // Research can get syntax right even though it cannot get
      // verification right, so the mechanical checks apply to drafts too —
      // catching a bad parameter now rather than after a test run.
      for (final draft in draftVariants) {
        final tool = toolById(draft.toolId);
        expect(tool, isNotNull, reason: '${draft.id} targets an unknown tool');
        if (tool!.flags.isEmpty) continue;

        for (final template in _templatesOf(draft)) {
          for (final match in _flag.allMatches(template)) {
            final spec = tool.specFor(match.group(0)!);
            expect(
              spec,
              isNotNull,
              reason:
                  '${draft.id} uses ${match.group(0)}, not a '
                  '${tool.name} parameter',
            );
            expect(
              spec!.acceptedBy(draft.modelLabel),
              isTrue,
              reason:
                  '${draft.id} declares ${draft.modelLabel}, which does '
                  'not accept ${spec.flag}',
            );
          }
        }
      }
    });

    test('every token resolves to a declared variable, and none is unused', () {
      for (final draft in draftVariants) {
        final declared = {for (final v in draft.variables) v.key};
        final used = <String>{};

        for (final template in _templatesOf(draft)) {
          for (final match in _token.allMatches(template)) {
            used.add(match.group(1)!);
          }
        }
        for (final step in draft.steps) {
          for (final input in step.inputs) {
            final key = input.variableKey;
            if (key != null) used.add(key);
          }
        }

        expect(
          used.difference(declared),
          isEmpty,
          reason: '${draft.id} uses tokens it never declares',
        );
        expect(
          declared.difference(used),
          isEmpty,
          reason: '${draft.id} declares variables it never uses',
        );
      }
    });

    test('every variable is documented and binds to a real contract key', () {
      final goals = {
        for (final g in [...sampleGoals, ...draftGoals]) g.id: g,
      };

      for (final draft in draftVariants) {
        final goal = goals[draft.goalId];
        expect(
          goal,
          isNotNull,
          reason: '${draft.id} points at an unknown goal',
        );
        final contractKeys = {for (final f in goal!.inputContract) f.key};

        for (final variable in draft.variables) {
          expect(variable.label, isNotEmpty);
          expect(
            variable.help,
            isNotEmpty,
            reason: '${draft.id}/${variable.key} has no help text',
          );
          expect(
            variable.example,
            isNotEmpty,
            reason: '${draft.id}/${variable.key} has no example',
          );

          final bindsTo = variable.bindsTo;
          if (bindsTo == null) continue;
          // bindsTo is what lets the tool switcher carry typed values
          // across tools. A typo here breaks the headline feature quietly.
          expect(
            contractKeys,
            contains(bindsTo),
            reason:
                '${draft.id}/${variable.key} binds to "$bindsTo", '
                'which is not on ${goal.id}\'s contract',
          );
        }
      }
    });

    test('draft goals use real taxonomy ids', () {
      for (final goal in draftGoals) {
        expect(
          useCaseById(goal.useCaseId),
          isNotNull,
          reason: '${goal.id} has an unknown use case',
        );
        expect(
          outputTypeById(goal.outputTypeId),
          isNotNull,
          reason: '${goal.id} has an unknown output type',
        );
        for (final niche in goal.nicheIds) {
          expect(
            nicheById(niche),
            isNotNull,
            reason: '${goal.id} has an unknown niche "$niche"',
          );
        }
      }
    });

    test('every step that produces something says what it produces', () {
      for (final draft in draftVariants) {
        for (final step in draft.steps) {
          expect(
            step.expectedOutput,
            isNotEmpty,
            reason: '${draft.id} step ${step.order} promises nothing',
          );
          if (step.actionType == StepActionType.prompt) {
            expect(
              step.prompt,
              isNotNull,
              reason:
                  '${draft.id} step ${step.order} is a prompt step '
                  'with no prompt',
            );
          }
        }
      }
    });
  });
}
