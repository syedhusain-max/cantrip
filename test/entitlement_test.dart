import 'package:flutter_test/flutter_test.dart';
import 'package:cantrip/models/entitlement.dart';
import 'package:cantrip/models/prompt_folder.dart';
import 'package:cantrip/state/entitlement_controller.dart';
import 'package:cantrip/state/entitlement_gate.dart';
import 'package:cantrip/state/library_state.dart';

void main() {
  group('entitlement', () {
    test(
      'the free tier has the whole library, only the workspace is capped',
      () {
        const free = Entitlement.free;

        // Nothing here caps reading prompts — that is the point of the model.
        expect(free.folderLimit, 1);
        expect(free.savedCopyLimit, 10);
        expect(free.folderDefaults, isFalse);
        expect(Entitlement.pro.folderLimit, isNull);
        expect(Entitlement.pro.savedCopyLimit, isNull);
      },
    );

    test('folders are capped at one on free and uncapped on pro', () {
      final library = LibraryState();
      final free = EntitlementGate(limits: Entitlement.free, library: library);

      expect(free.checkNewFolder(), isNull);
      library.createFolder('Acme', FolderType.client);
      expect(free.checkNewFolder(), LimitHit.folders);

      final pro = EntitlementGate(limits: Entitlement.pro, library: library);
      expect(pro.checkNewFolder(), isNull);
    });

    test('saved copies are counted across folders, not per folder', () {
      final library = LibraryState();
      final variant = library.allItems.first.variant;
      final folder = library.createFolder('Acme', FolderType.client);
      for (var i = 0; i < 10; i++) {
        library.forkToFolder(variant, folder.id);
      }

      expect(library.savedCopyCount, 10);
      expect(
        EntitlementGate(
          limits: Entitlement.free,
          library: library,
        ).checkNewSavedCopy(),
        LimitHit.savedCopies,
        reason: 'a second folder must not reset the allowance',
      );
      expect(
        EntitlementGate(
          limits: Entitlement.pro,
          library: library,
        ).checkNewSavedCopy(),
        isNull,
      );
    });

    test('new prompts are pro-only for 14 days, then free — never walled', () {
      final now = DateTime(2026, 9, 20);
      final free = EntitlementController();

      expect(
        free.isWithinNewContentWindow(
          now.subtract(const Duration(days: 3)),
          now: now,
        ),
        isTrue,
      );
      expect(
        free.isWithinNewContentWindow(
          now.subtract(const Duration(days: 15)),
          now: now,
        ),
        isFalse,
        reason: 'the delay expires, so the free library stays complete',
      );
    });

    test('signed out is free, and free is a real tier not a locked one', () {
      final controller = EntitlementController();

      expect(controller.tier, Tier.free);
      expect(controller.isPro, isFalse);
      expect(controller.limits.newContentDelay, const Duration(days: 14));
    });
  });
}
