import 'package:flutter/widgets.dart';

/// All Cantrip UI copy, keyed by locale code.
///
/// English only for now. To add Arabic, add an `'ar'` map with the same
/// keys and append `Locale('ar')` to `supportedLocales` in `app.dart` — no
/// screen code changes, since every screen looks strings up by key. RTL is
/// handled by Flutter once the locale is registered.
class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  /// Falls back to English, then to the key itself, so a missing
  /// translation degrades to something readable instead of crashing.
  String t(String key) =>
      _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'app.name': 'Cantrip',

      'nav.home': 'Home',
      'nav.library': 'Library',
      'nav.create': 'Create',
      'nav.saved': 'Saved',
      'nav.settings': 'Settings',

      'home.greeting': 'What do you want to create today?',
      'home.subtitle': 'Answer three questions and get the exact prompt for the tool you use.',
      'home.startGuided': 'Start guided flow',
      'home.browseByTool': 'Browse by AI tool',
      'home.browseByUseCase': 'Browse by use case',
      'home.browseByOutput': 'Browse by output type',
      'home.viewAll': 'View all',

      'wizard.title': 'Guided flow',
      'wizard.stepGoalTitle': 'What are you making?',
      'wizard.stepGoalHint': 'Pick the goal closest to what you need.',
      'wizard.stepInputTitle': 'What do you have to start from?',
      'wizard.stepInputHint': 'This decides which version of the recipe fits.',
      'wizard.stepToolTitle': 'Which tools can you use?',
      'wizard.stepToolHint': 'Pick every tool you have access to. Leave it empty and we\'ll recommend regardless.',
      'wizard.anyTool': 'Recommend anything',
      'wizard.showResult': 'Show recommendation',
      'wizard.recommended': 'Your recipe',
      'wizard.recommendedHint':
          'The closest match to your answers, ranked by what still works.',
      'wizard.alternatives': 'Same goal, other tools',
      'wizard.back': 'Back',
      'wizard.startOver': 'Start over',
      'wizard.noMatches': 'Nothing in the library matches that yet.',

      'library.title': 'Library',
      'library.searchHint': 'Search prompts and recipes',
      'library.filters': 'Filters',
      'library.clearFilters': 'Clear',
      'library.noResults': 'No prompts match those filters.',

      'filter.tool': 'AI tool',
      'filter.useCase': 'Use case',
      'filter.niche': 'Niche',
      'filter.outputType': 'Output type',
      'filter.inputMethod': 'Input method',
      'filter.apply': 'Apply filters',

      'detail.missing': 'That prompt is no longer in the library.',
      'detail.gallery': 'Before and after',
      'detail.before': 'Starting point',
      'detail.after': 'Result',
      'detail.lastVerified': 'Verified',
      'detail.verifiedOn': 'on',
      'detail.stillWorks': 'say it works',
      'detail.reportedBroken': 'report it broken',
      'detail.brokenWarning': 'Enough people report this as broken that it is being re-tested. Expect it to need edits.',
      'detail.lastChange': 'Last change',
      'detail.doesItWork': 'Did this work for you?',
      'detail.signalWorks': 'Still works',
      'detail.signalBroken': 'It\'s broken',
      'detail.switchTool': 'Use a different tool',
      'detail.switchToolHint': 'Same goal, rewritten for that tool. What you\'ve typed carries over.',
      'detail.variables': 'Fill in the details',
      'detail.livePreview': 'Your prompt',
      'detail.copyLink': 'Copy link to this prompt',
      'detail.copyPrompt': 'Copy prompt',
      'detail.copyJson': 'Copy as JSON',
      'detail.steps': 'Steps',
      'detail.step': 'Step',
      'detail.singlePrompt': 'Single prompt',
      'detail.runRecipe': 'Run step by step',
      'detail.expectedOutput': 'You should get',
      'detail.usesInput': 'Uses',
      'detail.fromStep': 'Carried from earlier step',
      'detail.negativePrompt': 'Negative prompt',
      'detail.settings': 'Settings',
      'detail.noToolPreselected': 'Any tool',
      'detail.suggestedTools': 'Works in',
      'detail.favourite': 'Add to favourites',
      'detail.unfavourite': 'Remove from favourites',
      'detail.fork': 'Save a copy',
      'detail.forkTitle': 'Save a copy',
      'detail.forkHint': 'Copies this into a folder so you can edit it freely.',
      'detail.forkedInto': 'Saved to',
      'detail.createAndFork': 'Create folder and save',

      'runner.title': 'Run the recipe',
      'runner.nextStep': 'Next step',
      'runner.finish': 'Done',
      'runner.carriedForward': 'From your earlier steps',
      'runner.whatDidYouGet': 'What did this produce?',
      'runner.notePlaceholder': 'e.g. Soul ID named "Mira"',

      'saved.title': 'Saved',
      'saved.favouritesTab': 'Favourites',
      'saved.foldersTab': 'Folders',
      'saved.newFolder': 'New folder',
      'saved.newFolderName': 'Folder name',
      'saved.personal': 'Personal',
      'saved.client': 'Client',
      'saved.emptyFavourites': 'Prompts you favourite show up here.',
      'saved.emptyFolders': 'Folders hold editable copies of prompts, grouped by client or project.',
      'saved.emptyFolderItems': 'Save a copy of a prompt to see it here.',
      'saved.deleteFolder': 'Delete folder',
      'saved.deleteFolderBody': 'Delete',
      'saved.removeFromFolder': 'Remove',
      'saved.needsAttention': 'saved prompts need checking',
      'saved.needsAttentionOne': 'saved prompt needs checking',
      'saved.needsAttentionBody':
          'The library version has been reported broken, or is no longer '
          'there. Your copy still works as you saved it.',

      'folder.defaults': 'Folder defaults',
      'folder.defaultsHint':
          'Set these once and every prompt saved into this folder fills '
          'itself in — across tools, not just this one.',
      'folder.defaultsEmpty':
          'Save a prompt into this folder first; its fields show up here.',
      'folder.export': 'Export as JSON',
      'folder.exported': 'Folder JSON copied',

      'saved.folderMissing': 'That folder no longer exists.',
      'saved.valuesSaved': 'details saved',
      'saved.upstreamUpdated': 'Library version updated since you saved this',
      'saved.forkOrphaned': 'Removed from the library',
      'saved.forkOrphanedBody':
          'The prompt this copy came from is no longer in the library.',

      'auth.title': 'Account',
      'auth.signIn': 'Sign in',
      'auth.signUp': 'Create account',
      'auth.signOut': 'Sign out',
      'auth.email': 'Email',
      'auth.password': 'Password',
      'auth.haveAccount': 'Already have an account? Sign in',
      'auth.needAccount': 'No account yet? Create one',
      'auth.why':
          'An account only syncs your saved prompts across devices. Everything '
          'here works without one.',
      'auth.signedInAs': 'Signed in as',
      'auth.confirmEmail':
          'Check your email and click the link to finish creating the account.',
      'auth.emailRequired': 'Enter your email address.',
      'auth.passwordTooShort': 'Use at least 8 characters.',
      'auth.syncOffer': 'Sign in to sync this across your devices',
      'auth.syncOfferAction': 'Sign in',

      'pro.title': 'Cantrip Pro',
      'pro.pitch':
          'The library is free, always. Pro is for using it on client work.',
      'pro.limitFolders':
          'Free keeps one folder. Pro gives you a folder per client, synced '
          'across your devices.',
      'pro.limitSavedCopies':
          'Free keeps 10 saved copies. Pro keeps as many as you need, each '
          'remembering what you typed.',
      'pro.limitFolderDefaults':
          'Set a client\'s brand once on the folder and every prompt saved '
          'into it fills itself in. That one is Pro.',
      'pro.limitExport': 'Exporting a folder as JSON is a Pro feature.',
      'pro.featureFolders': 'A folder per client, not just one',
      'pro.featureSavedCopies': 'Unlimited saved copies, with your values',
      'pro.featureDefaults': 'Folder defaults — set a brand once, reuse it',
      'pro.featureAlerts': 'Told when a prompt you saved stops working',
      'pro.featureEarly': 'Newly verified prompts on day one, not day 14',
      'pro.featureExport': 'Export a folder as JSON',
      'pro.comingSoon': 'Subscriptions open soon',
      'pro.comingSoonBody':
          'Pro isn\'t on sale yet. Nothing you save now is lost when it is — '
          'your folders and copies stay exactly where they are.',
      'pro.notNow': 'Not now',

      'settings.title': 'Settings',
      'settings.appearance': 'Appearance',
      'settings.light': 'Light',
      'settings.dark': 'Dark',
      'settings.system': 'System',
      'settings.language': 'Language',
      'settings.english': 'English',
      'settings.arabicComingSoon': 'Arabic — coming soon',
      'settings.about': 'About',
      'settings.aboutBody':
          'A library of tested prompts and multi-step recipes for AI creative '
          'tools. No account needed to browse or save — an account only syncs '
          'your saved prompts across devices. Every prompt shows when it was '
          'last verified and on which model.',

      'common.cancel': 'Cancel',
      'common.create': 'Create',
      'common.save': 'Save',
      'common.delete': 'Delete',
      'common.rename': 'Rename',
      'common.copiedPrompt': 'Prompt copied',
      'common.copiedLink': 'Link copied',
      'common.copiedJson': 'JSON copied',
    },
  };
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppStrings._values.containsKey(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
