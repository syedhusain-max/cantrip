import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../state/auth_controller.dart';

/// Sign in or create an account.
///
/// Reached only from Settings or the offer shown after a first save — never
/// as a gate. An account is a sync feature here, not an entry requirement,
/// and the copy says so.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _creatingAccount = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth, AppStrings strings) async {
    final email = _email.text.trim();
    final password = _password.text;

    // Checked here rather than at the server so a typo costs no round trip.
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = strings.t('auth.emailRequired'));
      return;
    }
    if (password.length < 8) {
      setState(() => _error = strings.t('auth.passwordTooShort'));
      return;
    }

    setState(() {
      _error = null;
      _notice = null;
    });

    final result = _creatingAccount
        ? await auth.signUp(email: email, password: password)
        : await auth.signIn(email: email, password: password);
    if (!mounted) return;

    switch (result) {
      case AuthSuccess():
        if (context.canPop()) context.pop();
      case AuthConfirmationRequired():
        setState(() => _notice = strings.t('auth.confirmEmail'));
      case AuthFailure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('auth.title'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.t('auth.why'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: strings.t('auth.email'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(auth, strings),
                    decoration: InputDecoration(
                      labelText: strings.t('auth.password'),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  if (_notice != null) ...[
                    const SizedBox(height: 12),
                    Text(_notice!, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: auth.busy ? null : () => _submit(auth, strings),
                    child: auth.busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            strings.t(
                              _creatingAccount ? 'auth.signUp' : 'auth.signIn',
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: auth.busy
                        ? null
                        : () => setState(() {
                            _creatingAccount = !_creatingAccount;
                            _error = null;
                            _notice = null;
                          }),
                    child: Text(
                      strings.t(
                        _creatingAccount
                            ? 'auth.haveAccount'
                            : 'auth.needAccount',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
