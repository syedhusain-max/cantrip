import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_controller.dart';

/// Supabase implementation of [AuthApi]. The only file that knows how
/// accounts are actually stored.
class SupabaseAuthApi implements AuthApi {
  final SupabaseClient client;

  const SupabaseAuthApi(this.client);

  @override
  String? get currentEmail => client.auth.currentUser?.email;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.session == null
          ? const AuthFailure(
              'Could not sign in. Check the email and password.',
            )
          : const AuthSuccess();
    } on AuthException catch (error) {
      return AuthFailure(error.message);
    } catch (_) {
      return const AuthFailure('Could not reach the server. Try again.');
    }
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      // No session means the project requires email confirmation, which is
      // the Supabase default.
      return response.session == null
          ? const AuthConfirmationRequired()
          : const AuthSuccess();
    } on AuthException catch (error) {
      return AuthFailure(error.message);
    } catch (_) {
      return const AuthFailure('Could not reach the server. Try again.');
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut();
}
