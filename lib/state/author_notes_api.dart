import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/author_note.dart';

/// Reading and writing the author's test records.
///
/// Behind an interface so the merge rules can be tested without a server,
/// and because a build with no backend has no author mode at all — the app
/// then shows the bundled library exactly as shipped.
abstract interface class AuthorNotesApi {
  /// Everyone can read notes, signed in or not: a verification nobody can
  /// see is worth nothing.
  Future<List<AuthorNote>> fetchAll();

  /// True only for accounts flagged as authors. Checked server-side too —
  /// this is for hiding UI, not for security.
  Future<bool> isAuthor();

  Future<void> save(AuthorNote note);
}

class SupabaseAuthorNotesApi implements AuthorNotesApi {
  final SupabaseClient client;

  const SupabaseAuthorNotesApi(this.client);

  @override
  Future<List<AuthorNote>> fetchAll() async {
    try {
      final rows = await client
          .from('author_notes')
          .select(
            'variant_id, tested_on, tested_model_label, works_on, fails_on, '
            'best_in_tool_id, verdict, note, creators_choice, red_flag, '
            'updated_at',
          );
      return [
        for (final row in rows)
          ?AuthorNote.fromJson(Map<String, dynamic>.from(row)),
      ];
    } catch (_) {
      // An unreachable server means the bundled library, unannotated —
      // never an error screen over content that is already on the device.
      return const [];
    }
  }

  @override
  Future<bool> isAuthor() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final row = await client
          .from('profiles')
          .select('is_author')
          .eq('id', userId)
          .maybeSingle();
      return row?['is_author'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> save(AuthorNote note) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('author_notes').upsert({
      ...note.toJson(),
      'author_id': userId,
    });
  }
}
