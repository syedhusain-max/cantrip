import 'package:flutter/foundation.dart';

/// What a sign-in attempt came back with.
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

/// The account was created but can't be used until the emailed link is
/// clicked. Supabase does this by default, and silently treating it as a
/// success would leave the user looking at a signed-out app with no
/// explanation.
class AuthConfirmationRequired extends AuthResult {
  const AuthConfirmationRequired();
}

class AuthFailure extends AuthResult {
  final String message;
  const AuthFailure(this.message);
}

/// The authentication calls the app makes, behind an interface so the sign-in
/// flow can be tested without a server.
abstract interface class AuthApi {
  String? get currentEmail;
  Future<AuthResult> signIn({required String email, required String password});
  Future<AuthResult> signUp({required String email, required String password});
  Future<void> signOut();
}

/// Holds who is signed in, if anyone.
///
/// Accounts are optional in this app: browsing and saving work without one,
/// and an account only adds sync across devices. So this controller has
/// three states, not two — [isAvailable] is false when the build has no
/// backend configured, and the UI hides account settings entirely rather
/// than offering a sign-in that cannot work.
class AuthController extends ChangeNotifier {
  final AuthApi? api;

  /// Called after a successful sign-in, to re-read user data now that there
  /// is an account to read it for.
  final Future<void> Function()? onSignedIn;

  /// Called after sign-out. This wipes the local cache: the data is safe on
  /// the server, and leaving it on the device would hand one account's
  /// folders to whoever signs in next — the first-sign-in merge would
  /// cheerfully upload them into the new account.
  final Future<void> Function()? onSignedOut;

  AuthController({this.api, this.onSignedIn, this.onSignedOut});

  bool get isAvailable => api != null;
  String? get email => api?.currentEmail;
  bool get isSignedIn => email != null;

  bool _busy = false;
  bool get busy => _busy;

  bool _syncOfferShown = false;

  /// True once, the first time a signed-out user saves something on a build
  /// that could sync it. Deliberately not persisted: a nudge that returns
  /// every launch is a nag, and the account is optional by design.
  bool shouldOfferSync() {
    if (!isAvailable || isSignedIn || _syncOfferShown) return false;
    _syncOfferShown = true;
    return true;
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) => _run(() => api!.signIn(email: email, password: password));

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) => _run(() => api!.signUp(email: email, password: password));

  Future<void> signOut() async {
    if (api == null || _busy) return;
    _setBusy(true);
    try {
      await api!.signOut();
      await onSignedOut?.call();
    } finally {
      _setBusy(false);
    }
  }

  Future<AuthResult> _run(Future<AuthResult> Function() action) async {
    if (api == null) {
      return const AuthFailure('This build has no account server configured.');
    }
    if (_busy) return const AuthFailure('Already working on it.');

    _setBusy(true);
    try {
      final result = await action();
      if (result is AuthSuccess) await onSignedIn?.call();
      return result;
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
