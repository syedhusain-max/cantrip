import 'package:flutter/material.dart';

import '../data/tool_registry.dart';
import '../l10n/app_strings.dart';
import '../models/author_note.dart';
import '../models/prompt_variant.dart';

/// Where the author records what happened when they ran a prompt.
///
/// Everything here is an attestation with a name on it, which is why the
/// date is not optional in practice: the badge does not light up without
/// one. Popularity is absent by design — it is computed from real signals
/// and cannot be set here at all.
class AuthorNoteSheet extends StatefulWidget {
  final PromptVariant variant;
  final AuthorNote? existing;
  final Future<void> Function(AuthorNote) onSave;

  const AuthorNoteSheet({
    super.key,
    required this.variant,
    required this.existing,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required PromptVariant variant,
    required AuthorNote? existing,
    required Future<void> Function(AuthorNote) onSave,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) =>
        AuthorNoteSheet(variant: variant, existing: existing, onSave: onSave),
  );

  @override
  State<AuthorNoteSheet> createState() => _AuthorNoteSheetState();
}

class _AuthorNoteSheetState extends State<AuthorNoteSheet> {
  late AuthorVerdict _verdict = widget.existing?.verdict ?? AuthorVerdict.works;
  late DateTime? _testedOn = widget.existing?.testedOn;
  late String? _testedModel =
      widget.existing?.testedModelLabel ?? widget.variant.modelLabel;
  late final Set<String> _worksOn = {...?widget.existing?.worksOn};
  late final Set<String> _failsOn = {...?widget.existing?.failsOn};
  late bool _creatorsChoice = widget.existing?.creatorsChoice ?? false;
  late bool _redFlag = widget.existing?.redFlag ?? false;
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _testedOn ?? now,
      firstDate: DateTime(2023),
      // A test cannot have happened tomorrow.
      lastDate: now,
    );
    if (picked != null) setState(() => _testedOn = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final note = AuthorNote(
      variantId: widget.variant.id,
      testedOn: _testedOn,
      testedModelLabel: _testedModel,
      worksOn: _worksOn.toList(),
      failsOn: _failsOn.toList(),
      verdict: _verdict,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      creatorsChoice: _creatorsChoice,
      redFlag: _redFlag,
      updatedAt: DateTime.now(),
    );
    await widget.onSave(note);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final models = _availableModels();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.t('author.title'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              strings.t('author.hint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),

            Text(
              strings.t('author.verdict'),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final v in AuthorVerdict.values)
                  ChoiceChip(
                    label: Text(v.label),
                    selected: _verdict == v,
                    onSelected: (_) => setState(() => _verdict = v),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            Text(
              strings.t('author.testedOn'),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event, size: 18),
              label: Text(
                _testedOn == null
                    ? strings.t('author.pickDate')
                    : '${_testedOn!.year}-'
                          '${_testedOn!.month.toString().padLeft(2, '0')}-'
                          '${_testedOn!.day.toString().padLeft(2, '0')}',
              ),
            ),

            if (models.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                strings.t('author.testedModel'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in models)
                    ChoiceChip(
                      label: Text(m),
                      selected: _testedModel == m,
                      onSelected: (_) => setState(() => _testedModel = m),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              // Two lists rather than a pass/fail switch: "works on v6.1,
              // fails on v7" is the most useful thing to know about a
              // prompt and has nowhere else to live.
              _ModelList(
                label: strings.t('author.worksOn'),
                models: models,
                selected: _worksOn,
                onToggle: (m) => setState(() {
                  _worksOn.contains(m) ? _worksOn.remove(m) : _worksOn.add(m);
                  _failsOn.remove(m);
                }),
              ),
              const SizedBox(height: 12),
              _ModelList(
                label: strings.t('author.failsOn'),
                models: models,
                selected: _failsOn,
                onToggle: (m) => setState(() {
                  _failsOn.contains(m) ? _failsOn.remove(m) : _failsOn.add(m);
                  _worksOn.remove(m);
                }),
              ),
            ],

            const SizedBox(height: 18),
            TextField(
              controller: _note,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: strings.t('author.note'),
                hintText: strings.t('author.notePlaceholder'),
              ),
            ),

            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _creatorsChoice,
              onChanged: (v) => setState(() => _creatorsChoice = v),
              title: Text(strings.t('author.creatorsChoice')),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _redFlag,
              onChanged: (v) => setState(() => _redFlag = v),
              title: Text(strings.t('author.redFlag')),
            ),

            const SizedBox(height: 14),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(strings.t('author.save')),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Model labels worth offering: the tool's own list from the registry,
  /// plus whatever the variant itself declares — so a label the registry
  /// hasn't caught up with is still selectable rather than unrecordable.
  List<String> _availableModels() => {
    if (widget.variant.modelLabel.isNotEmpty) widget.variant.modelLabel,
    ...?toolById(widget.variant.toolId)?.modelLabels,
  }.toList();
}

class _ModelList extends StatelessWidget {
  final String label;
  final List<String> models;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _ModelList({
    required this.label,
    required this.models,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        children: [
          for (final m in models)
            FilterChip(
              label: Text(m),
              selected: selected.contains(m),
              onSelected: (_) => onToggle(m),
            ),
        ],
      ),
    ],
  );
}
