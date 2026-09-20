import 'package:flutter/widgets.dart';

/// All PromptCraft UI copy, keyed by locale code.
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
      'app.name': 'PromptCraft',

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
      'saved.folderMissing': 'That folder no longer exists.',
      'saved.valuesSaved': 'details saved',
      'saved.upstreamUpdated': 'Library version updated since you saved this',
      'saved.forkOrphaned': 'Removed from the library',
      'saved.forkOrphanedBody':
          'The prompt this copy came from is no longer in the library.',

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
          'A local library of tested prompts and multi-step recipes for AI creative '
          'tools. No account needed, nothing leaves this device, and every prompt '
          'shows when it was last verified and on which model.',

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
