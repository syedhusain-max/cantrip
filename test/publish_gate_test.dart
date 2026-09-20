import 'package:flutter_test/flutter_test.dart';

import 'package:cantrip/data/sample_library.dart';
import 'package:cantrip/data/taxonomy_registry.dart';
import 'package:cantrip/data/tool_registry.dart';
import 'package:cantrip/models/gallery_asset.dart';
import 'package:cantrip/models/prompt_variant.dart';

/// The automated half of the publishing gate.
///
/// These run on every commit, so a prompt cannot reach users with an
/// unfilled placeholder, an undocumented variable, a parameter the target
/// tool no longer accepts, or no proof that it works. The judgement checks
/// (does it run clean from the example values, does a second variable set
/// also produce something usable) stay human — but everything mechanical
/// is enforced here rather than relying on remembering.
///
/// PR-3 is the one that earns its keep: it is what catches a prompt still
/// written against Midjourney v6's `--cref` after v7 renamed it `--oref`.

/// Matches `{{variable_key}}` tokens.
final _token = RegExp(r'\{\{\s*([a-zA-Z0-9_]+)\s*\}\}');

/// Matches CLI-style flags such as `--ar 3:4`.
final _flag = RegExp(r'(?<![\w-])--[a-zA-Z][a-zA-Z0-9-]*');

Iterable<String> _templatesOf(PromptVariant v) sync* {
  for (final step in v.steps) {
    if (step.prompt != null) yield step.prompt!;
    if (step.negativePrompt != null) yield step.negativePrompt!;
    yield* step.settings.values;
  }
}

void main() {
  final goalsById = {for (final g in sampleGoals) g.id: g};

  test('the library is not empty and every variant points at a real goal', () {
    expect(sampleVariants, isNotEmpty);
    for (final v in sampleVariants) {
      expect(
        goalsById.containsKey(v.goalId),
        isTrue,
        reason: '${v.id} references unknown goal ${v.goalId}',
      );
    }
  });

  group('PR-1 no orphan placeholders', () {
    test('every token in a template resolves to a declared variable', () {
      for (final v in sampleVariants) {
        final declared = {for (final x in v.variables) x.key};
        for (final template in _templatesOf(v)) {
          for (final match in _token.allMatches(template)) {
            final key = match.group(1)!;
            expect(
              declared,
              contains(key),
              reason: '${v.id} uses {{$key}} but never declares it',
            );
          }
        }
      }
    });

    test('every declared variable is actually used somewhere', () {
      for (final v in sampleVariants) {
        final used = <String>{};
        for (final template in _templatesOf(v)) {
          for (final match in _token.allMatches(template)) {
            used.add(match.group(1)!);
          }
        }
        // A variable may also be consumed by a non-prompt step as an input.
        for (final step in v.steps) {
          for (final input in step.inputs) {
            final key = input.variableKey;
            if (key != null) used.add(key);
          }
        }
        for (final variable in v.variables) {
          expect(
            used,
            contains(variable.key),
            reason: '${v.id} declares ${variable.key} but never uses it',
          );
        }
      }
    });
  });

  group('PR-2 every variable is documented', () {
    test('label, help and example are present and enums list options', () {
      for (final v in sampleVariants) {
        for (final variable in v.variables) {
          final where = '${v.id}.${variable.key}';
          expect(
            variable.label.trim(),
            isNotEmpty,
            reason: '$where has no label',
          );
          expect(
            variable.help.trim(),
            isNotEmpty,
            reason: '$where has no help',
          );
          expect(
            variable.example.trim(),
            isNotEmpty,
            reason: '$where has no example value',
          );
          if (variable.options.isNotEmpty) {
            expect(
              variable.options.length,
              greaterThan(1),
              reason: '$where offers a single choice',
            );
          }
        }
      }
    });

    test('a default, where given, is a valid choice for an enum', () {
      for (final v in sampleVariants) {
        for (final variable in v.variables) {
          if (variable.options.isEmpty) continue;
          final value = variable.defaultValue;
          if (value == null || value.isEmpty) continue;
          expect(
            variable.options,
            contains(value),
            reason:
                '${v.id}.${variable.key} defaults to a value not in options',
          );
        }
      }
    });
  });

  group('PR-3 native syntax is real syntax', () {
    test('every flag used is on the target tool\'s allowlist', () {
      for (final v in sampleVariants) {
        for (final step in v.steps) {
          final toolId = step.toolId ?? v.toolId;
          final tool = toolById(toolId);
          if (tool == null || tool.syntaxFlags.isEmpty) continue;
          final allowed = tool.syntaxFlags.toSet();

          for (final template in _templatesOf(v)) {
            for (final match in _flag.allMatches(template)) {
              final flag = match.group(0)!;
              expect(
                allowed,
                contains(flag),
                reason:
                    '${v.id} step ${step.order} uses $flag, which is not in '
                    '${tool.name}\'s known parameters for ${v.modelLabel}',
              );
            }
          }
        }
      }
    });

    test('a declared model label is one the tool actually exposes', () {
      for (final v in sampleVariants) {
        if (v.modelLabel.isEmpty) continue;
        final tool = toolById(v.toolId);
        if (tool == null || tool.modelLabels.isEmpty) continue;
        expect(
          tool.modelLabels,
          contains(v.modelLabel),
          reason:
              '${v.id} claims model "${v.modelLabel}", unknown to ${tool.name}',
        );
      }
    });
  });

  group('PR-4 gallery proof attached', () {
    test('at least one before and two after images', () {
      for (final v in sampleVariants) {
        expect(
          v.gallery.where((a) => a.kind == AssetKind.before).length,
          greaterThanOrEqualTo(1),
          reason: '${v.id} has no "before" image',
        );
        expect(
          v.gallery.where((a) => a.kind == AssetKind.after).length,
          greaterThanOrEqualTo(2),
          reason: '${v.id} needs two result images, one per variable set',
        );
      }
    });

    test('results are attributed to the variable set that produced them', () {
      for (final v in sampleVariants) {
        final sets = {
          for (final a in v.gallery)
            if (a.kind == AssetKind.after && a.variableSet != null)
              a.variableSet,
        };
        expect(
          sets.length,
          greaterThanOrEqualTo(2),
          reason:
              '${v.id} must show two different variable sets — that is what '
              'separates a reusable template from a lucky one-off',
        );
      }
    });
  });

  group('PR-5 freshness recorded', () {
    test('a verification date is set and is not in the future', () {
      final now = DateTime.now();
      for (final v in sampleVariants) {
        expect(
          v.freshness.verifiedOn.isAfter(now),
          isFalse,
          reason: '${v.id} claims to be verified in the future',
        );
      }
    });

    test('a tool with version labels has one recorded against it', () {
      for (final v in sampleVariants) {
        final tool = toolById(v.toolId);
        if (tool == null || tool.modelLabels.isEmpty) continue;
        expect(
          v.freshness.verifiedAgainstModelLabel.trim(),
          isNotEmpty,
          reason:
              '${v.id} does not say which ${tool.name} version it was tested on',
        );
      }
    });
  });

  group('PR-8 a stated failure boundary', () {
    test('every variant names at least one way it fails', () {
      for (final v in sampleVariants) {
        final guardrails = [for (final s in v.steps) ...s.guardrails];
        expect(
          guardrails,
          isNotEmpty,
          reason:
              '${v.id} states no limitation — an author who cannot name one '
              'has not tested it enough to publish',
        );
      }
    });
  });

  group('taxonomy integrity', () {
    test('every goal and variant references known taxonomy ids', () {
      for (final g in sampleGoals) {
        expect(
          useCaseById(g.useCaseId),
          isNotNull,
          reason: '${g.id} has unknown use case ${g.useCaseId}',
        );
        expect(
          outputTypeById(g.outputTypeId),
          isNotNull,
          reason: '${g.id} has unknown output type ${g.outputTypeId}',
        );
        for (final n in g.nicheIds) {
          expect(
            nicheById(n),
            isNotNull,
            reason: '${g.id} has unknown niche $n',
          );
        }
      }
      for (final v in sampleVariants) {
        expect(
          inputMethodById(v.inputMethodId),
          isNotNull,
          reason: '${v.id} has unknown input method ${v.inputMethodId}',
        );
        if (v.toolId != null) {
          expect(
            toolById(v.toolId),
            isNotNull,
            reason: '${v.id} references unknown tool ${v.toolId}',
          );
        }
      }
    });

    test('ids are unique', () {
      final goalIds = sampleGoals.map((g) => g.id).toList();
      final variantIds = sampleVariants.map((v) => v.id).toList();
      expect(
        goalIds.toSet().length,
        goalIds.length,
        reason: 'duplicate goal id',
      );
      expect(
        variantIds.toSet().length,
        variantIds.length,
        reason: 'duplicate variant id',
      );
    });
  });

  group('recipe wiring', () {
    test('steps are ordered from 1 with no gaps', () {
      for (final v in sampleVariants) {
        final orders = [for (final s in v.steps) s.order];
        expect(
          orders,
          List.generate(v.steps.length, (i) => i + 1),
          reason: '${v.id} has mis-ordered steps',
        );
      }
    });

    test('a step can only consume an output an earlier step produced', () {
      for (final v in sampleVariants) {
        final producedSoFar = <String>{};
        for (final step in v.steps) {
          for (final id in step.carriedInputIds) {
            expect(
              producedSoFar,
              contains(id),
              reason:
                  '${v.id} step ${step.order} consumes "$id" before any step '
                  'produces it',
            );
          }
          final produces = step.produces;
          if (produces != null) producedSoFar.add(produces.id);
        }
      }
    });

    test('a variant with no preselected tool suggests tools on its steps', () {
      for (final v in sampleVariants) {
        if (v.toolId != null) continue;
        for (final step in v.steps) {
          expect(
            step.toolId != null || step.suggestedToolIds.isNotEmpty,
            isTrue,
            reason:
                '${v.id} step ${step.order} has no tool and suggests none, so '
                'the user is told nothing about where to run it',
          );
        }
      }
    });
  });

  group('cross-tool goal variants', () {
    test('variants of one goal bind onto that goal\'s input contract', () {
      for (final v in sampleVariants) {
        final goal = goalsById[v.goalId]!;
        final contractKeys = {for (final f in goal.inputContract) f.key};
        for (final variable in v.variables) {
          final bindsTo = variable.bindsTo;
          if (bindsTo == null) continue;
          expect(
            contractKeys,
            contains(bindsTo),
            reason:
                '${v.id}.${variable.key} binds to "$bindsTo", which is not in '
                '${goal.id}\'s input contract — values would not carry across '
                'a tool switch',
          );
        }
      }
    });

    test('a goal served by several tools can actually carry values across', () {
      final byGoal = <String, List<PromptVariant>>{};
      for (final v in sampleVariants) {
        byGoal.putIfAbsent(v.goalId, () => []).add(v);
      }
      for (final entry in byGoal.entries) {
        if (entry.value.length < 2) continue;
        for (final variant in entry.value) {
          final bound = variant.variables
              .where((x) => x.bindsTo != null)
              .length;
          expect(
            bound,
            greaterThan(0),
            reason:
                '${variant.id} shares goal ${entry.key} with another tool but '
                'binds nothing, so switching tools would lose everything typed',
          );
        }
      }
    });
  });
}
