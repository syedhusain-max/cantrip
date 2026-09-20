import 'prompt_variable.dart';

/// A creative outcome, independent of any tool.
///
/// Goals are the spine of the library. A goal knows what the user is trying
/// to achieve and what inputs that requires semantically; it knows nothing
/// about any tool's syntax. Tool-specific text lives in the variants that
/// point at this goal, which is what makes "same goal, different tool" a
/// first-class relationship instead of two unrelated entries that happen to
/// share a tag.
class Goal {
  final String id;
  final String title;

  /// Taxonomy ids, resolved through the registries.
  final String useCaseId;
  final List<String> nicheIds;
  final String outputTypeId;
  final List<String> inputMethodIds;

  final String summary;

  /// The semantic inputs this goal needs, whatever tool ends up serving it.
  ///
  /// Variants map their own tool-named variables onto these keys via
  /// [PromptVariable.bindsTo]. That mapping is what allows the detail screen
  /// to swap tools without discarding what the user already typed.
  final List<ContractField> inputContract;

  const Goal({
    required this.id,
    required this.title,
    required this.useCaseId,
    this.nicheIds = const [],
    required this.outputTypeId,
    this.inputMethodIds = const [],
    required this.summary,
    this.inputContract = const [],
  });
}
