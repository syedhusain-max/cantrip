import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/taxonomy_registry.dart';
import '../data/tool_registry.dart';
import '../l10n/app_strings.dart';
import '../models/freshness.dart';
import '../models/gallery_asset.dart';
import '../models/prompt_folder.dart';
import '../models/prompt_step.dart';
import '../models/prompt_variable.dart';
import '../models/prompt_variant.dart';
import '../router/app_router.dart';
import '../state/auth_controller.dart';
import '../state/library_state.dart';
import '../utils/date_format.dart';
import '../utils/share_link.dart';
import '../widgets/freshness_pill.dart';
import '../widgets/gallery_placeholder.dart';
import '../widgets/step_card.dart';
import '../widgets/tool_badge.dart';
import '../widgets/variable_field.dart';

/// The detail view: proof, freshness, fillable variables, live preview, and
/// the tool switcher that keeps the goal while swapping the prompt.
class PromptDetailScreen extends StatefulWidget {
  final String variantId;

  /// Both set when opened from a folder, so edits save back to that copy.
  final String? folderId;
  final String? forkId;

  const PromptDetailScreen({
    super.key,
    required this.variantId,
    this.folderId,
    this.forkId,
  });

  bool get isSavedCopy => folderId != null && forkId != null;

  @override
  State<PromptDetailScreen> createState() => _PromptDetailScreenState();
}

class _PromptDetailScreenState extends State<PromptDetailScreen> {
  late String _variantId = widget.variantId;
  Map<String, String> _values = {};
  bool _seeded = false;

  /// Values the user typed on variants they've already visited, so
  /// switching tools and switching back restores what was lost in the swap.
  final Map<String, Map<String, String>> _valuesByVariant = {};

  PromptVariant? _resolveVariant(LibraryState library) =>
      library.variantById(_variantId);

  /// Seeds the form: a saved copy reopens with the values the user last
  /// entered, and a folder's shared defaults fill anything still blank.
  Map<String, String> _seedValues(LibraryState library, PromptVariant variant) {
    final values = variant.initialValues();

    final folderId = widget.folderId;
    if (folderId != null) {
      final defaults =
          library.folderById(folderId)?.variableDefaults ?? const {};
      for (final v in variant.variables) {
        final contractKey = v.bindsTo;
        if (contractKey == null) continue;
        final preset = defaults[contractKey];
        if (preset != null && preset.isNotEmpty) values[v.key] = preset;
      }
    }

    final forkId = widget.forkId;
    if (forkId != null && folderId != null) {
      final saved = library.forkById(folderId, forkId)?.values ?? const {};
      for (final e in saved.entries) {
        if (e.value.trim().isNotEmpty) values[e.key] = e.value;
      }
    }
    return values;
  }

  /// Persists edits back onto the saved copy. Only applies when opened
  /// from a folder — editing a library prompt never mutates the library.
  void _persistIfSavedCopy(LibraryState library) {
    if (!widget.isSavedCopy) return;
    if (_variantId != widget.variantId) return; // switched tools; don't clobber
    library.saveForkValues(widget.folderId!, widget.forkId!, _values);
  }

  void _switchTo(PromptVariant from, PromptVariant to) {
    setState(() {
      _valuesByVariant[from.id] = Map.of(_values);
      // Restore what the user had here before, otherwise carry across what
      // they typed on the variant they're leaving.
      _values =
          _valuesByVariant[to.id] ??
          PromptVariant.carryValues(from: from, to: to, values: _values);
      _variantId = to.id;
    });
  }

  Future<void> _copy(String text, String confirmationKey) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.strings.t(confirmationKey)),
        behavior: SnackBarBehavior.floating,
        width: 320,
      ),
    );
  }

  String _asJson(PromptVariant variant, LibraryState library) {
    final goal = library.goalById(variant.goalId);
    final map = {
      'goal': goal?.title,
      'variant': variant.title,
      'tool': toolName(variant.toolId, fallback: 'none preselected'),
      'model_label': variant.modelLabel,
      'use_case': useCaseLabel(goal?.useCaseId),
      'output_type': outputTypeLabel(goal?.outputTypeId),
      'input_method': inputMethodLabel(variant.inputMethodId),
      'verified_on': formatDate(variant.freshness.verifiedOn),
      'status': library.statusFor(variant).label,
      'variables': [
        for (final v in variant.variables)
          {
            'key': v.key,
            'binds_to': v.bindsTo,
            'type': v.type.label,
            'value': (_values[v.key]?.trim().isNotEmpty ?? false)
                ? _values[v.key]
                : v.initialValue,
          },
      ],
      'steps': [
        for (final s in variant.steps)
          {
            'order': s.order,
            'title': s.title,
            'tool': s.toolId == null ? null : toolName(s.toolId),
            'action': s.actionType.label,
            if (s.where != null) 'where': s.where,
            if (s.hasPromptText) 'prompt': variant.render(s.prompt!, _values),
            if (s.negativePrompt != null)
              'negative_prompt': variant.render(s.negativePrompt!, _values),
            if (s.settings.isNotEmpty)
              'settings': {
                for (final e in s.settings.entries)
                  e.key: variant.render(e.value, _values),
              },
            'expected_output': s.expectedOutput,
            if (s.guardrails.isNotEmpty) 'guardrails': s.guardrails,
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Confirms the save, then — once per run, and only if signing in could
  /// actually do something — offers sync as an action on the same snackbar.
  /// Saving already worked; this is an offer, never a gate.
  void _confirmSaved(String folderName, AppStrings strings) {
    final auth = context.read<AuthController>();
    final offerSync = auth.shouldOfferSync();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          offerSync
              ? strings.t('auth.syncOffer')
              : '${strings.t('detail.forkedInto')} $folderName',
        ),
        behavior: SnackBarBehavior.floating,
        width: 360,
        action: offerSync
            ? SnackBarAction(
                label: strings.t('auth.syncOfferAction'),
                onPressed: () => context.push(Routes.signIn),
              )
            : null,
      ),
    );
  }

  void _showForkSheet(LibraryState library, PromptVariant variant) {
    final strings = context.strings;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _ForkSheet(
        folders: library.folders,
        onPick: (folderId) {
          // Carry what's already typed into the saved copy.
          library.forkToFolder(variant, folderId, values: _values);
          Navigator.of(sheetContext).pop();
          final name = library.folderById(folderId)?.name ?? '';
          _confirmSaved(name, strings);
        },
        onCreate: (name, type) {
          final folder = library.createFolder(name, type);
          library.forkToFolder(variant, folder.id, values: _values);
          Navigator.of(sheetContext).pop();
          _confirmSaved(name, strings);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final library = context.watch<LibraryState>();
    final variant = _resolveVariant(library);

    if (variant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(strings.t('detail.missing'))),
      );
    }

    if (!_seeded) {
      _values = _seedValues(library, variant);
      _seeded = true;
    }

    final goal = library.goalById(variant.goalId);
    final isFavourite = library.isFavourite(variant.id);
    final siblings = library.variantsForGoal(
      variant.goalId,
      excludeVariantId: variant.id,
    );
    final status = library.statusFor(variant);
    final signals = library.signalsFor(variant);
    final mySignal = library.mySignal(variant.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          variant.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: strings.t('detail.copyLink'),
            icon: const Icon(Icons.link),
            // Always the library prompt, never the saved copy: a fork is
            // local to this device, so a link to one would open nothing on
            // the recipient's.
            onPressed: () => _copy(
              shareLinkFor(Routes.prompt(variant.id)),
              'common.copiedLink',
            ),
          ),
          IconButton(
            tooltip: isFavourite
                ? strings.t('detail.unfavourite')
                : strings.t('detail.favourite'),
            icon: Icon(isFavourite ? Icons.favorite : Icons.favorite_border),
            color: isFavourite ? theme.colorScheme.error : null,
            onPressed: () => library.toggleFavourite(variant.id),
          ),
          IconButton(
            tooltip: strings.t('detail.fork'),
            icon: const Icon(Icons.call_split),
            onPressed: () => _showForkSheet(library, variant),
          ),
        ],
      ),
      floatingActionButton: variant.isRecipe
          ? FloatingActionButton.extended(
              onPressed: () => context.push(
                Routes.recipe(variant.id),
                extra: Map<String, String>.from(_values),
              ),
              icon: const Icon(Icons.play_arrow),
              label: Text(strings.t('detail.runRecipe')),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 840
                ? 840.0
                : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: width,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                  children: [
                    // ---------------------------------------------- header
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ToolBadge(
                          toolId: variant.toolId,
                          fallbackLabel: strings.t('detail.noToolPreselected'),
                        ),
                        FreshnessPill(status: status),
                        if (variant.modelLabel.isNotEmpty)
                          _Pill(label: variant.modelLabel),
                        _Pill(
                          label: variant.isRecipe
                              ? '${variant.steps.length} ${strings.t('detail.steps').toLowerCase()}'
                              : strings.t('detail.singlePrompt'),
                        ),
                        _Pill(label: inputMethodLabel(variant.inputMethodId)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      goal?.title ?? variant.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      variant.summary,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // ------------------------------------------- freshness
                    const SizedBox(height: 20),
                    _FreshnessBlock(
                      variant: variant,
                      status: status,
                      signals: signals,
                      mySignal: mySignal,
                      onSignal: (works) =>
                          library.submitSignal(variant.id, works: works),
                    ),

                    // ----------------------------------------- tool switch
                    if (siblings.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _SectionLabel(strings.t('detail.switchTool')),
                      const SizedBox(height: 6),
                      Text(
                        strings.t('detail.switchToolHint'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            avatar: const Icon(Icons.check, size: 16),
                            label: Text(
                              toolName(
                                variant.toolId,
                                fallback: strings.t('detail.noToolPreselected'),
                              ),
                            ),
                            selected: true,
                            onSelected: (_) {},
                          ),
                          for (final sibling in siblings)
                            ChoiceChip(
                              label: Text(
                                toolName(
                                  sibling.variant.toolId,
                                  fallback: strings.t(
                                    'detail.noToolPreselected',
                                  ),
                                ),
                              ),
                              selected: false,
                              onSelected: (_) =>
                                  _switchTo(variant, sibling.variant),
                            ),
                        ],
                      ),
                    ],

                    // --------------------------------------------- gallery
                    if (variant.gallery.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _SectionLabel(strings.t('detail.gallery')),
                      const SizedBox(height: 10),
                      _Gallery(variant: variant),
                    ],

                    // ------------------------------------------- variables
                    if (variant.variables.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _SectionLabel(strings.t('detail.variables')),
                      const SizedBox(height: 12),
                      for (final v in variant.variables)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: VariableField(
                            key: ValueKey('${variant.id}-${v.key}'),
                            variable: v,
                            value: _values[v.key] ?? '',
                            onChanged: (value) {
                              setState(() => _values[v.key] = value);
                              _persistIfSavedCopy(library);
                            },
                          ),
                        ),
                    ],

                    // ----------------------------------------- live preview
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SectionLabel(strings.t('detail.livePreview')),
                        ),
                        TextButton.icon(
                          onPressed: () => _copy(
                            _asJson(variant, library),
                            'common.copiedJson',
                          ),
                          icon: const Icon(Icons.data_object, size: 17),
                          label: Text(strings.t('detail.copyJson')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final step in variant.steps)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StepCard(
                          step: step,
                          variant: variant,
                          values: _values,
                          showStepNumber: variant.isRecipe,
                          onCopy: (text) => _copy(text, 'common.copiedPrompt'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

/// Verification date, the model it was verified against, and the binary
/// signal that replaces star ratings in Phase 1.
class _FreshnessBlock extends StatelessWidget {
  final PromptVariant variant;
  final FreshnessStatus status;
  final FreshnessSignals signals;
  final bool? mySignal;
  final ValueChanged<bool> onSignal;

  const _FreshnessBlock({
    required this.variant,
    required this.status,
    required this.signals,
    required this.mySignal,
    required this.onSignal,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = variant.freshness.verifiedAgainstModelLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaLine(
                icon: Icons.event_available_outlined,
                text:
                    '${strings.t('detail.lastVerified')} ${formatDate(variant.freshness.verifiedOn)}',
              ),
              if (label.isNotEmpty)
                _MetaLine(
                  icon: Icons.memory,
                  text: '${strings.t('detail.verifiedOn')} $label',
                ),
              _MetaLine(
                icon: Icons.thumb_up_outlined,
                text: '${signals.works} ${strings.t('detail.stillWorks')}',
              ),
              if (signals.broken > 0)
                _MetaLine(
                  icon: Icons.thumb_down_outlined,
                  text:
                      '${signals.broken} ${strings.t('detail.reportedBroken')}',
                ),
            ],
          ),
          if (status == FreshnessStatus.broken) ...[
            const SizedBox(height: 12),
            Text(
              strings.t('detail.brokenWarning'),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          if (variant.freshness.history.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${strings.t('detail.lastChange')}: ${variant.freshness.history.last.reason}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const Divider(height: 26),
          Text(
            strings.t('detail.doesItWork'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onSignal(true),
                  icon: Icon(
                    mySignal == true
                        ? Icons.check_circle
                        : Icons.thumb_up_outlined,
                    size: 17,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mySignal == true ? scheme.primary : null,
                  ),
                  label: Text(strings.t('detail.signalWorks')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onSignal(false),
                  icon: Icon(
                    mySignal == false
                        ? Icons.cancel
                        : Icons.thumb_down_outlined,
                    size: 17,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mySignal == false ? scheme.error : null,
                  ),
                  label: Text(strings.t('detail.signalBroken')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(text, style: theme.textTheme.labelMedium),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  final PromptVariant variant;

  const _Gallery({required this.variant});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final before = variant.beforeAssets;
    final after = variant.afterAssets;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tall = constraints.maxWidth < 520;
        final tileHeight = tall ? 120.0 : 150.0;

        Widget column(String title, List<GalleryAsset> assets) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final a in assets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: tileHeight,
                  child: GalleryPlaceholder(asset: a),
                ),
              ),
          ],
        );

        if (tall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (before.isNotEmpty) column(strings.t('detail.before'), before),
              if (after.isNotEmpty) column(strings.t('detail.after'), after),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (before.isNotEmpty)
              Expanded(child: column(strings.t('detail.before'), before)),
            if (before.isNotEmpty && after.isNotEmpty)
              const SizedBox(width: 12),
            if (after.isNotEmpty)
              Expanded(child: column(strings.t('detail.after'), after)),
          ],
        );
      },
    );
  }
}

/// Pick an existing folder or make one, then fork into it.
class _ForkSheet extends StatefulWidget {
  final List<PromptFolder> folders;
  final ValueChanged<String> onPick;
  final void Function(String name, FolderType type) onCreate;

  const _ForkSheet({
    required this.folders,
    required this.onPick,
    required this.onCreate,
  });

  @override
  State<_ForkSheet> createState() => _ForkSheetState();
}

class _ForkSheetState extends State<_ForkSheet> {
  final _controller = TextEditingController();
  FolderType _type = FolderType.personal;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('detail.forkTitle'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                strings.t('detail.forkHint'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              for (final folder in widget.folders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    folder.type == FolderType.personal
                        ? Icons.person_outline
                        : Icons.business_outlined,
                  ),
                  title: Text(folder.name),
                  subtitle: Text('${folder.items.length} saved'),
                  onTap: () => widget.onPick(folder.id),
                ),
              if (widget.folders.isNotEmpty) const Divider(height: 26),
              Text(
                strings.t('saved.newFolder'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: strings.t('saved.newFolderName'),
                ),
                onSubmitted: (_) => _create(),
              ),
              const SizedBox(height: 10),
              SegmentedButton<FolderType>(
                segments: [
                  ButtonSegment(
                    value: FolderType.personal,
                    label: Text(strings.t('saved.personal')),
                  ),
                  ButtonSegment(
                    value: FolderType.client,
                    label: Text(strings.t('saved.client')),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _create,
                  child: Text(strings.t('detail.createAndFork')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _create() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.onCreate(name, _type);
  }
}
