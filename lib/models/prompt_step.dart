import 'package:flutter/material.dart';

/// What a step asks the user to do. Not every step is prompt text — a recipe
/// that trains an identity starts with an upload step whose useful content
/// is the UI path, not a paste-able string.
enum StepActionType { prompt, upload, setting, export }

extension StepActionTypeX on StepActionType {
  String get label => switch (this) {
    StepActionType.prompt => 'Prompt',
    StepActionType.upload => 'Upload',
    StepActionType.setting => 'Setting',
    StepActionType.export => 'Export',
  };

  IconData get icon => switch (this) {
    StepActionType.prompt => Icons.notes_outlined,
    StepActionType.upload => Icons.upload_outlined,
    StepActionType.setting => Icons.tune,
    StepActionType.export => Icons.download_outlined,
  };
}

/// Where a step's input comes from: either a variable the user fills, or an
/// earlier step's named output.
///
/// Modelled as an explicit reference rather than a "uses previous step"
/// boolean so a recipe can fan in from several earlier steps, and so the
/// runner can name exactly what to carry forward.
class StepInput {
  /// Variable key, when this input is user-supplied.
  final String? variableKey;

  /// [StepOutput.id] of an earlier step, when this input is carried forward.
  final String? fromStepOutputId;

  final String? label;

  const StepInput.variable(String key, {this.label})
    : variableKey = key,
      fromStepOutputId = null;

  const StepInput.fromStep(String outputId, {this.label})
    : fromStepOutputId = outputId,
      variableKey = null;

  bool get isCarriedForward => fromStepOutputId != null;
}

/// A named thing a step produces, which later steps can consume by id.
class StepOutput {
  final String id;
  final String label;

  /// e.g. 'tool_artifact', 'image', 'image[]', 'text', 'video'
  final String type;

  const StepOutput({required this.id, required this.label, required this.type});
}

/// One ordered step of a variant. A single-prompt variant has exactly one.
class PromptStep {
  final int order;
  final String title;

  /// Steps carry their own tool id, so a recipe can span several tools
  /// (generate a still in one, animate it in another) and a tool-agnostic
  /// recipe can leave individual steps unassigned.
  final String? toolId;

  /// Tools suggested when [toolId] is null.
  final List<String> suggestedToolIds;

  final String? modelLabel;
  final StepActionType actionType;

  /// Where in the tool's UI this happens, for non-prompt steps.
  final String? where;

  /// Prompt text in the tool's native syntax, with `{{key}}` placeholders.
  /// Null for upload/setting/export steps.
  final String? prompt;

  /// Tools with a separate negative-prompt field get one; tools without
  /// leave it null rather than jamming negatives into the main prompt.
  final String? negativePrompt;

  /// Native settings the user sets alongside the prompt (aspect ratio,
  /// seed, character selection). Values may contain `{{key}}` placeholders.
  final Map<String, String> settings;

  final List<StepInput> inputs;
  final StepOutput? produces;
  final String expectedOutput;

  /// Author-stated limits and gotchas. The publish gate requires at least
  /// one on every variant — an author who can't name a failure mode hasn't
  /// tested enough to publish.
  final List<String> guardrails;

  final int? estMinutes;

  const PromptStep({
    required this.order,
    required this.title,
    this.toolId,
    this.suggestedToolIds = const [],
    this.modelLabel,
    this.actionType = StepActionType.prompt,
    this.where,
    this.prompt,
    this.negativePrompt,
    this.settings = const {},
    this.inputs = const [],
    this.produces,
    required this.expectedOutput,
    this.guardrails = const [],
    this.estMinutes,
  });

  bool get hasPromptText => prompt != null && prompt!.trim().isNotEmpty;

  /// Outputs of earlier steps this step depends on.
  List<String> get carriedInputIds => [
    for (final i in inputs)
      if (i.fromStepOutputId != null) i.fromStepOutputId!,
  ];
}
