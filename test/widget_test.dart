import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:cantrip/app.dart';
import 'package:cantrip/router/app_router.dart';
import 'package:cantrip/l10n/app_strings.dart';
import 'package:cantrip/models/fork.dart';
import 'package:cantrip/models/freshness.dart';
import 'package:cantrip/models/prompt_folder.dart';
import 'package:cantrip/screens/prompt_detail_screen.dart';
import 'package:cantrip/widgets/prompt_card.dart';
import 'package:cantrip/state/auth_controller.dart';
import 'package:cantrip/state/library_state.dart';
import 'package:cantrip/utils/share_link.dart';
import 'package:cantrip/theme/theme_controller.dart';

Widget buildTestApp() => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeController()),
    ChangeNotifierProvider(create: (_) => LibraryState()),
    // No api: the local-only build, which is what most tests exercise.
    ChangeNotifierProvider(create: (_) => AuthController()),
  ],
  child: const CantripApp(),
);

/// Builds the real router at [location], which is how a shared link or a
/// browser address-bar entry arrives. Returns the router too, so a test can
/// assert on where navigation actually left the user.
({Widget app, GoRouter router}) buildAppAt(String location) {
  final router = createRouter(initialLocation: location);
  final app = MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeController()),
      ChangeNotifierProvider(create: (_) => LibraryState()),
      ChangeNotifierProvider(create: (_) => AuthController()),
    ],
    child: MaterialApp.router(
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      routerConfig: router,
    ),
  );
  return (app: app, router: router);
}

Widget wrapScreen(Widget screen) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeController()),
    ChangeNotifierProvider(create: (_) => LibraryState()),
    // No api: the local-only build, which is what most tests exercise.
    ChangeNotifierProvider(create: (_) => AuthController()),
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
  group('shell', () {
    testWidgets('home shows the guided prompt and all five tabs', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('What do you want to create today?'), findsOneWidget);
      for (final tab in ['Home', 'Library', 'Create', 'Saved', 'Settings']) {
        expect(find.text(tab), findsOneWidget, reason: 'missing $tab tab');
      }
    });

    testWidgets('library lists the seeded prompts', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      expect(find.textContaining('SAMPLE'), findsWidgets);
    });
  });

  group('detail screen', () {
    testWidgets('shows the goal, freshness and the filled prompt', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapScreen(const PromptDetailScreen(variantId: 'var_hgf_soulid')),
      );
      await tester.pumpAndSettle();

      // Goal title, not the variant title, headlines the page.
      expect(
        find.text('A consistent AI avatar I can reuse across scenes'),
        findsOneWidget,
      );
      expect(find.text('Your prompt'), findsOneWidget);
      expect(find.text('Fill in the details'), findsOneWidget);

      // Defaults are substituted into the rendered prompt. (The token form
      // still appears beside each variable field as its label, which is why
      // this checks the prompt text itself rather than the whole screen.)
      expect(find.textContaining('Mira, cream linen blazer'), findsOneWidget);
      expect(find.textContaining('shot on Sony A7IV'), findsOneWidget);
    });

    testWidgets('switching tools keeps the goal and carries typed values', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapScreen(const PromptDetailScreen(variantId: 'var_hgf_soulid')),
      );
      await tester.pumpAndSettle();

      // Type a character name into the Higgsfield variant.
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Kaya');
      await tester.pumpAndSettle();

      // Switch to the OpenArt variant of the same goal.
      await tester.tap(find.widgetWithText(ChoiceChip, 'OpenArt'));
      await tester.pumpAndSettle();

      // Same goal…
      expect(
        find.text('A consistent AI avatar I can reuse across scenes'),
        findsOneWidget,
      );
      // …different tool-native syntax (OpenArt has a negative prompt field,
      // Higgsfield does not)…
      expect(find.text('Negative prompt'), findsOneWidget);
      // …and the typed value carried across via binds_to, even though the
      // variable is called trigger_word here and character_name there.
      expect(find.textContaining('Kaya'), findsWidgets);
    });
  });

  group('freshness', () {
    test('status decays with age and flips on broken signals', () {
      // Fixed clock so these assertions don't drift over time.
      final library = LibraryState(now: DateTime(2026, 9, 20));

      final fresh = library.variantById('var_hgf_soulid')!;
      expect(library.statusFor(fresh).label, 'Verified');

      // Verified 2026-07-10, past the 60-day aging threshold.
      final aging = library.variantById('var_oa_char2')!;
      expect(library.statusFor(aging).label, 'Aging');

      // Verified 2026-06-05, past the 90-day review threshold.
      final stale = library.variantById('var_kling_turntable')!;
      expect(library.statusFor(stale).label, 'Needs review');

      // 5 broken of 13 signals is over the 20% threshold.
      final broken = library.variantById('var_mj_realestate_kit')!;
      expect(library.statusFor(broken).label, 'Reported broken');
    });

    test('a broken report moves the count and cannot be double-counted', () {
      final library = LibraryState(now: DateTime(2026, 9, 20));
      final variant = library.variantById('var_hgf_soulid')!;
      final before = library.signalsFor(variant);

      library.submitSignal(variant.id, works: false);
      expect(library.signalsFor(variant).broken, before.broken + 1);

      // Submitting the same signal again is a no-op.
      library.submitSignal(variant.id, works: false);
      expect(library.signalsFor(variant).broken, before.broken + 1);

      // Changing your mind withdraws the previous vote.
      library.submitSignal(variant.id, works: true);
      expect(library.signalsFor(variant).broken, before.broken);
      expect(library.signalsFor(variant).works, before.works + 1);
    });
  });

  group('filtering', () {
    test('each axis narrows results independently', () {
      final library = LibraryState(now: DateTime(2026, 9, 20));

      expect(library.allItems.length, 8);
      expect(
        library.filtered(const LibraryFilter(toolId: 'higgsfield')).length,
        1,
      );
      expect(
        library
            .filtered(const LibraryFilter(useCaseId: 'avatar_creation'))
            .length,
        2,
      );
      expect(
        library.filtered(const LibraryFilter(outputTypeId: 'brand_kit')).length,
        2,
      );
      expect(
        library
            .filtered(const LibraryFilter(inputMethodId: 'own_photo'))
            .length,
        3,
      );
      // Three: both avatar-goal variants plus the HeyGen talking-avatar
      // video, whose goal text also mentions avatars.
      expect(library.filtered(const LibraryFilter(search: 'avatar')).length, 3);
    });

    test(
      'tool filter matches recipes that merely include the tool in a step',
      () {
        final library = LibraryState(now: DateTime(2026, 9, 20));
        // The HeyGen recipe scripts in Claude at step 1, so filtering by
        // Claude must surface it even though its primary tool is HeyGen.
        final claudeResults = library.filtered(
          const LibraryFilter(toolId: 'claude'),
        );
        expect(
          claudeResults.map((i) => i.variant.id),
          contains('var_heygen_ugc'),
        );
      },
    );

    test('broken and stale prompts sort below healthy ones', () {
      final library = LibraryState(now: DateTime(2026, 9, 20));
      final results = library.filtered(const LibraryFilter());
      final ids = results.map((i) => i.variant.id).toList();

      // The broken one and the needs-review one both sink to the bottom;
      // between themselves they stay ordered by verification date.
      expect(
        ids.sublist(ids.length - 2),
        containsAll(['var_mj_realestate_kit', 'var_kling_turntable']),
      );
      expect(ids.first, isNot('var_mj_realestate_kit'));
    });
  });

  group('folders', () {
    test('saving a copy references the original and keeps filled values', () {
      final library = LibraryState(now: DateTime(2026, 9, 20));
      final folder = library.createFolder('Acme Co', FolderType.personal);
      final original = library.variantById('var_hgf_soulid')!;

      final fork = library.forkToFolder(
        original,
        folder.id,
        values: {'character_name': 'Kaya'},
      )!;

      expect(folder.items, hasLength(1));
      expect(fork.sourceVariantId, original.id);
      expect(fork.values['character_name'], 'Kaya');
      expect(library.sourceOf(fork)!.id, original.id);
      // The library entry is untouched.
      expect(library.variantById('var_hgf_soulid')!.title, original.title);
    });

    test('renaming and re-filling a saved copy does not touch the library', () {
      final library = LibraryState(now: DateTime(2026, 9, 20));
      final folder = library.createFolder('Beta Ltd', FolderType.client);
      final original = library.variantById('var_hgf_soulid')!;
      final fork = library.forkToFolder(original, folder.id)!;

      library.renameFork(folder.id, fork.id, 'Beta avatar');
      library.saveForkValues(folder.id, fork.id, {'character_name': 'Noor'});

      final reloaded = library.forkById(folder.id, fork.id)!;
      expect(reloaded.title, 'Beta avatar');
      expect(reloaded.values['character_name'], 'Noor');
      expect(library.variantById('var_hgf_soulid')!.title, original.title);
    });

    test('a saved copy knows when the library version has moved on', () {
      final library = LibraryState(now: DateTime(2026, 9, 20));
      final folder = library.createFolder('Gamma', FolderType.personal);
      final variant = library.variantById('var_hgf_soulid')!;
      final fork = library.forkToFolder(variant, folder.id)!;

      // Saved against the current version, so nothing to flag.
      expect(library.hasUpstreamUpdate(fork), isFalse);

      // Simulate having saved it before the last re-verification.
      final stale = Fork(
        id: 'f-old',
        sourceVariantId: variant.id,
        sourceVerifiedOn: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(library.hasUpstreamUpdate(stale), isTrue);
    });
  });

  group('routing', () {
    test('a filter survives the round trip through a URL', () {
      const filter = LibraryFilter(
        search: 'avatar',
        toolId: 'openart',
        outputTypeId: 'image',
      );

      final restored = LibraryFilter.fromQueryParameters(
        Uri.parse(Routes.libraryWith(filter)).queryParameters,
      );

      expect(restored, filter);
      // Unset axes stay out of the URL rather than showing up as empties.
      expect(filter.toQueryParameters().containsKey('niche'), isFalse);
    });

    testWidgets('a prompt link opens that prompt directly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildAppAt('/prompt/var_hgf_soulid').app);
      await tester.pumpAndSettle();

      expect(
        find.text('A consistent AI avatar I can reuse across scenes'),
        findsOneWidget,
      );
    });

    testWidgets('a filtered library link lands filtered and titled', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildAppAt('/library?tool=openart').app);
      await tester.pumpAndSettle();

      // The single active axis names the page.
      expect(find.widgetWithText(AppBar, 'OpenArt'), findsOneWidget);

      final library = LibraryState();
      final expected = library.filtered(const LibraryFilter(toolId: 'openart'));
      expect(expected, isNotEmpty);
      expect(find.byType(PromptCard), findsNWidgets(expected.length));
    });

    testWidgets('opening a prompt puts it in the URL, so it can be copied', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final (:app, :router) = buildAppAt('/library?tool=openart');
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PromptCard).first);
      await tester.pumpAndSettle();

      // go_router hides imperative pushes from the URL unless we opt in;
      // without the opt-in this still renders the page but the address bar
      // keeps saying /library, and there is no link to share.
      expect(router.state.uri.toString(), '/prompt/var_oa_char2');
    });

    testWidgets('the copy-link button copies a link to the library prompt', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      // Opened as a saved copy, which is the case that could get this wrong.
      await tester.pumpWidget(
        buildAppAt('/prompt/var_hgf_soulid?folder=f1&fork=k1').app,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.link));
      await tester.pumpAndSettle();

      // The link points at the library prompt: a fork is local to one
      // device, so folder/fork in a shared link would open nothing.
      expect(copied, '$shareBaseUrl/#/prompt/var_hgf_soulid');
    });

    testWidgets('each tab has its own URL', (tester) async {
      await tester.pumpWidget(buildAppAt('/saved').app);
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsWidgets);
    });
  });

  group('persistence', () {
    test('folders and saved values survive a JSON round trip', () {
      final folder = PromptFolder(
        id: 'f1',
        name: 'Acme Co',
        type: FolderType.client,
        items: [
          Fork(
            id: 'fk1',
            sourceVariantId: 'var_hgf_soulid',
            title: 'Acme avatar',
            values: {'character_name': 'Kaya', 'scene': 'studio'},
            sourceVerifiedOn: DateTime(2026, 9, 2),
            createdAt: DateTime(2026, 9, 20),
          ),
        ],
        variableDefaults: {'primary_color': '#FF0000'},
      );

      final restored = PromptFolder.fromJson(
        jsonDecode(jsonEncode(folder.toJson())) as Map<String, dynamic>,
      )!;

      expect(restored.id, 'f1');
      expect(restored.name, 'Acme Co');
      expect(restored.type, FolderType.client);
      expect(restored.variableDefaults['primary_color'], '#FF0000');
      expect(restored.items, hasLength(1));
      expect(restored.items.first.title, 'Acme avatar');
      expect(restored.items.first.values['character_name'], 'Kaya');
      expect(restored.items.first.sourceVariantId, 'var_hgf_soulid');
    });

    test('malformed stored data is skipped rather than crashing', () {
      // Storage can hold data written by an older version, or be corrupted.
      expect(PromptFolder.fromJson({'name': 'no id'}), isNull);
      expect(Fork.fromJson({'id': 'x'}), isNull);

      final partial = PromptFolder.fromJson({
        'id': 'f2',
        'name': 'Half broken',
        'items': [
          {'id': 'ok', 'sourceVariantId': 'v1'},
          {'garbage': true},
        ],
      })!;
      // The valid entry survives; the junk one is dropped.
      expect(partial.items, hasLength(1));
      expect(partial.items.first.id, 'ok');
    });
  });
}
