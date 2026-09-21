import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cantrip/l10n/app_strings.dart';
import 'package:cantrip/screens/settings_screen.dart';
import 'package:cantrip/screens/sign_in_screen.dart';
import 'package:cantrip/state/auth_controller.dart';
import 'package:cantrip/state/author_notes_controller.dart';
import 'package:cantrip/state/entitlement_controller.dart';
import 'package:cantrip/theme/theme_controller.dart';

class FakeAuthApi implements AuthApi {
  @override
  String? currentEmail;

  AuthResult nextResult = const AuthSuccess();
  int signOutCalls = 0;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (nextResult is AuthSuccess) currentEmail = email;
    return nextResult;
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    if (nextResult is AuthSuccess) currentEmail = email;
    return nextResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    currentEmail = null;
  }
}

Widget wrap(Widget screen, AuthController auth) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeController()),
    ChangeNotifierProvider.value(value: auth),
    ChangeNotifierProvider(create: (_) => EntitlementController()),
    ChangeNotifierProvider(create: (_) => AuthorNotesController()),
  ],
  child: MaterialApp(
    localizationsDelegates: const [
      AppStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: screen,
  ),
);

void main() {
  group('auth', () {
    test('a build with no backend offers no account at all', () {
      final auth = AuthController();

      expect(auth.isAvailable, isFalse);
      expect(auth.isSignedIn, isFalse);
    });

    test(
      'signing in re-reads user data, signing out wipes the device',
      () async {
        var reloads = 0;
        var wipes = 0;
        final api = FakeAuthApi();
        final auth = AuthController(
          api: api,
          onSignedIn: () async => reloads++,
          onSignedOut: () async => wipes++,
        );

        await auth.signIn(email: 'a@b.com', password: 'password1');
        expect(auth.isSignedIn, isTrue);
        expect(reloads, 1, reason: 'the store now answers for an account');

        await auth.signOut();
        expect(auth.isSignedIn, isFalse);
        expect(
          wipes,
          1,
          reason: 'one account must not leave data for the next',
        );
      },
    );

    test(
      'a new account awaiting confirmation is not treated as signed in',
      () async {
        var reloads = 0;
        final api = FakeAuthApi()
          ..nextResult = const AuthConfirmationRequired();
        final auth = AuthController(
          api: api,
          onSignedIn: () async => reloads++,
        );

        final result = await auth.signUp(
          email: 'a@b.com',
          password: 'password1',
        );

        expect(result, isA<AuthConfirmationRequired>());
        expect(auth.isSignedIn, isFalse);
        expect(reloads, 0);
      },
    );

    testWidgets('settings hides the account section without a backend', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const SettingsScreen(), AuthController()));
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsNothing);
      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('settings shows the signed-in email and can sign out', (
      tester,
    ) async {
      final api = FakeAuthApi()..currentEmail = 'owner@example.com';
      final auth = AuthController(api: api);

      await tester.pumpWidget(wrap(const SettingsScreen(), auth));
      await tester.pumpAndSettle();

      expect(find.text('owner@example.com'), findsOneWidget);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(api.signOutCalls, 1);
      expect(find.text('owner@example.com'), findsNothing);
    });

    testWidgets('a short password is rejected before any network call', (
      tester,
    ) async {
      final api = FakeAuthApi();
      await tester.pumpWidget(
        wrap(const SignInScreen(), AuthController(api: api)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'a@b.com');
      await tester.enterText(find.byType(TextField).last, 'short');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(api.currentEmail, isNull, reason: 'never reached the server');
    });

    test(
      'the sync offer appears once, and only when it could do something',
      () {
        final localOnly = AuthController();
        expect(
          localOnly.shouldOfferSync(),
          isFalse,
          reason: 'no backend, so signing in would achieve nothing',
        );

        final signedIn = AuthController(
          api: FakeAuthApi()..currentEmail = 'owner@example.com',
        );
        expect(signedIn.shouldOfferSync(), isFalse);

        final signedOut = AuthController(api: FakeAuthApi());
        expect(signedOut.shouldOfferSync(), isTrue);
        expect(
          signedOut.shouldOfferSync(),
          isFalse,
          reason: 'offer, not a nag',
        );
      },
    );

    testWidgets('a failed sign-in shows the reason', (tester) async {
      final api = FakeAuthApi()
        ..nextResult = const AuthFailure('Invalid login credentials');
      await tester.pumpWidget(
        wrap(const SignInScreen(), AuthController(api: api)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'a@b.com');
      await tester.enterText(find.byType(TextField).last, 'password1');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid login credentials'), findsOneWidget);
    });
  });
}
