import '../models/entitlement.dart';
import 'library_state.dart';

/// Answers "may they do this?" for the actions that have limits.
///
/// Kept out of [LibraryState] on purpose. The library is about prompts and
/// what the user saved; entitlement is a commercial policy that will change
/// far more often than the data model. Mixing them means every pricing
/// experiment edits the file that holds the app's core state.
class EntitlementGate {
  final Entitlement limits;
  final LibraryState library;

  const EntitlementGate({required this.limits, required this.library});

  /// Null when allowed; the specific limit when not, so the paywall can
  /// name the thing the user just tried to do.
  LimitHit? checkNewFolder() =>
      limits.allowsAnotherFolder(library.folders.length)
      ? null
      : LimitHit.folders;

  LimitHit? checkNewSavedCopy() =>
      limits.allowsAnotherSavedCopy(library.savedCopyCount)
      ? null
      : LimitHit.savedCopies;

  LimitHit? checkFolderDefaults() =>
      limits.folderDefaults ? null : LimitHit.folderDefaults;

  LimitHit? checkExport() => limits.exportFolders ? null : LimitHit.export;
}
