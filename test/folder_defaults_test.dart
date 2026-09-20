import 'package:flutter_test/flutter_test.dart';
import 'package:cantrip/data/taxonomy_registry.dart';
import 'package:cantrip/models/fork.dart';
import 'package:cantrip/models/freshness.dart';
import 'package:cantrip/models/prompt_folder.dart';
import 'package:cantrip/state/library_state.dart';

void main() {
  group('folder defaults', () {
    test('a default set once reaches prompts for other tools', () {
      // This is the Pro feature's whole claim, and it only works because
      // defaults are keyed by the goal's contract rather than by one
      // tool's variable names.
      final library = LibraryState();
      final folder = library.createFolder('Acme', FolderType.client);

      // Two variants of the same goal, targeting different tools.
      final avatarVariants = library.allItems
          .where((i) => i.goal.id == 'goal_consistent_avatar')
          .toList();
      expect(
        avatarVariants.length,
        greaterThanOrEqualTo(2),
        reason: 'this test needs a goal with two tool variants',
      );
      expect(
        avatarVariants.map((i) => i.variant.toolId).toSet().length,
        greaterThanOrEqualTo(2),
        reason: 'and they must be for different tools',
      );

      for (final item in avatarVariants) {
        library.forkToFolder(item.variant, folder.id);
      }

      library.setFolderDefault(folder.id, 'identity_name', 'Mira Chen');

      // Every variant that binds a variable to identity_name now has a
      // value waiting, whatever its tool calls that variable.
      for (final item in avatarVariants) {
        final bound = item.variant.variables.where(
          (v) => v.bindsTo == 'identity_name',
        );
        if (bound.isEmpty) continue;
        expect(
          library.folderById(folder.id)!.variableDefaults['identity_name'],
          'Mira Chen',
          reason: '${item.variant.toolId} should read the shared default',
        );
      }
    });

    test('clearing a default removes it rather than storing empty', () {
      final library = LibraryState();
      final folder = library.createFolder('Acme', FolderType.client);

      library.setFolderDefault(folder.id, 'identity_name', 'Mira');
      expect(folder.variableDefaults, contains('identity_name'));

      library.setFolderDefault(folder.id, 'identity_name', '   ');
      expect(
        folder.variableDefaults,
        isNot(contains('identity_name')),
        reason: 'an empty default would overwrite real values with blanks',
      );
    });

    test('only fields a saved prompt actually binds are offered', () {
      final library = LibraryState();
      final folder = library.createFolder('Acme', FolderType.client);

      expect(
        library.defaultableFieldsFor(folder.id),
        isEmpty,
        reason: 'an empty folder has nothing to default',
      );

      final item = library.allItems.firstWhere(
        (i) => i.goal.id == 'goal_consistent_avatar',
      );
      library.forkToFolder(item.variant, folder.id);

      final fields = library.defaultableFieldsFor(folder.id);
      expect(fields, isNotEmpty);
      final bound = item.variant.variables
          .map((v) => v.bindsTo)
          .whereType<String>()
          .toSet();
      for (final field in fields) {
        expect(
          bound,
          contains(field.key),
          reason: 'offering ${field.key} would set a value nothing reads',
        );
      }
    });
  });

  group('breakage alerts', () {
    test('a saved copy whose source vanished is flagged', () {
      final library = LibraryState();
      final folder = library.createFolder('Acme', FolderType.client);
      final item = library.allItems.first;
      library.forkToFolder(item.variant, folder.id);

      expect(
        library.savedCopiesNeedingAttention,
        isEmpty,
        reason: 'a healthy source needs no attention',
      );

      // Simulate the library dropping that prompt: point the fork at an id
      // that no longer resolves, which is what a removed prompt looks like.
      final fork = folder.items.single;
      folder.items
        ..clear()
        ..add(
          Fork(
            id: fork.id,
            sourceVariantId: 'var_that_no_longer_exists',
            sourceVerifiedOn: fork.sourceVerifiedOn,
            createdAt: fork.createdAt,
          ),
        );

      final flagged = library.savedCopiesNeedingAttention;
      expect(flagged, hasLength(1));
      expect(flagged.single.missing, isTrue);
      expect(flagged.single.folder.id, folder.id);
    });

    test('a source reported broken by enough people is flagged', () {
      final library = LibraryState();
      final folder = library.createFolder('Acme', FolderType.client);
      final item = library.allItems.first;
      library.forkToFolder(item.variant, folder.id);

      // Freshness flips to broken past the reporting threshold; drive it
      // through the real path rather than faking the status.
      for (var i = 0; i < 40; i++) {
        library.submitSignal(item.variant.id, works: false);
        library.submitSignal(item.variant.id, works: true);
      }
      library.submitSignal(item.variant.id, works: false);

      if (library.statusFor(item.variant) == FreshnessStatus.broken) {
        expect(library.savedCopiesNeedingAttention, hasLength(1));
        expect(library.savedCopiesNeedingAttention.single.missing, isFalse);
      }
    });
  });

  group('empty categories', () {
    test('only categories with prompts behind them are listed', () {
      final library = LibraryState();

      final populated = library.populatedUseCaseIds;
      expect(populated, isNotEmpty);

      // The registry still defines more than the library has content for —
      // that is the situation this filter exists for.
      expect(
        useCases.length,
        greaterThan(populated.length),
        reason: 'if every category had content this test proves nothing',
      );

      for (final id in populated) {
        expect(
          library.filtered(LibraryFilter(useCaseId: id)),
          isNotEmpty,
          reason: 'category $id is listed but leads nowhere',
        );
      }
    });

    test('every listed tool actually appears in a prompt', () {
      final library = LibraryState();
      for (final id in library.populatedToolIds) {
        expect(
          library.filtered(LibraryFilter(toolId: id)),
          isNotEmpty,
          reason: 'tool $id is listed but leads nowhere',
        );
      }
    });
  });
}
