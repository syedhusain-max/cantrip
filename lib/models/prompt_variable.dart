import 'package:flutter/material.dart';

/// The kind of input a variable takes. Unlike tools and taxonomy, these are
/// an enum on purpose: each one maps to a specific input widget, so adding a
/// type is genuinely a code change.
enum VariableType {
  text,
  number,
  enumChoice,
  color,
  image,
  imageList,
  assetRef,
}

extension VariableTypeX on VariableType {
  String get label => switch (this) {
    VariableType.text => 'Text',
    VariableType.number => 'Number',
    VariableType.enumChoice => 'Choice',
    VariableType.color => 'Color',
    VariableType.image => 'Image',
    VariableType.imageList => 'Images',
    VariableType.assetRef => 'Asset',
  };

  IconData get icon => switch (this) {
    VariableType.text => Icons.text_fields,
    VariableType.number => Icons.numbers,
    VariableType.enumChoice => Icons.list_alt,
    VariableType.color => Icons.palette,
    VariableType.image => Icons.image,
    VariableType.imageList => Icons.burst_mode_outlined,
    VariableType.assetRef => Icons.attachment,
  };
}

/// Limits on what a variable accepts. Tool requirements differ for the same
/// semantic input — Higgsfield trains a Soul ID from 20-80 photos while
/// OpenArt's Character 2.0 needs a single reference — so the constraint
/// lives on the variant's variable, not on the goal's contract.
class VariableConstraints {
  final int? minItems;
  final int? maxItems;
  final int? maxLength;
  final num? min;
  final num? max;

  const VariableConstraints({
    this.minItems,
    this.maxItems,
    this.maxLength,
    this.min,
    this.max,
  });

  /// Human-readable summary shown under the field, e.g. "20-80 files".
  String? get summary {
    if (minItems != null && maxItems != null) {
      return '$minItems-$maxItems files';
    }
    if (minItems != null) return 'at least $minItems files';
    if (maxItems != null) return 'up to $maxItems files';
    if (maxLength != null) return 'up to $maxLength characters';
    if (min != null && max != null) return '$min-$max';
    return null;
  }
}

/// A fillable input on a prompt or recipe step, referenced in prompt text as
/// `{{key}}`.
class PromptVariable {
  /// Token used in this variant's prompt text.
  final String key;

  /// The goal-level input contract key this variable satisfies, or null if
  /// it is tool-specific with no cross-tool equivalent (e.g. a seed lock).
  ///
  /// This is what lets the detail screen switch tools while keeping what the
  /// user already typed: values move across variants by matching [bindsTo],
  /// not by matching [key], because the tool-native names differ.
  final String? bindsTo;

  final VariableType type;
  final String label;
  final String help;
  final String example;
  final String? defaultValue;
  final bool required;
  final List<String> options;
  final VariableConstraints constraints;

  const PromptVariable({
    required this.key,
    this.bindsTo,
    required this.type,
    required this.label,
    required this.help,
    required this.example,
    this.defaultValue,
    this.required = true,
    this.options = const [],
    this.constraints = const VariableConstraints(),
  });

  String get initialValue => defaultValue ?? '';
}

/// One semantic input declared by a [Goal]. Variants map their own
/// variables onto these via [PromptVariable.bindsTo].
class ContractField {
  final String key;
  final VariableType type;
  final String label;
  final List<String> options;

  const ContractField({
    required this.key,
    required this.type,
    required this.label,
    this.options = const [],
  });
}
