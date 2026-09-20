/// Supabase connection details, supplied at build time.
///
/// Passed with `--dart-define` rather than committed, so the repo carries no
/// project URL or key:
///
/// ```
/// flutter run -d chrome \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
/// ```
///
/// `SUPABASE_ANON_KEY` is accepted as well: Supabase renamed that key to
/// "publishable", and older projects still show the old name in the
/// dashboard.
///
/// With nothing defined the app runs exactly as it did before the backend
/// existed: local storage only, no sign-in, no network. That is deliberate —
/// a missing key should degrade the app, not break it.
abstract final class BackendConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');

  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// This key is a public identifier, not a secret: it only ever grants what
  /// row-level security allows, which is why it can ship inside a client
  /// build at all. The service-role key must never appear in this app.
  static String get publishableKey =>
      _publishableKey.isNotEmpty ? _publishableKey : _anonKey;

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
