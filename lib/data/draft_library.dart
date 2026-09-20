import '../models/goal.dart';
import '../models/prompt_step.dart';
import '../models/prompt_variable.dart';

/// Prompts written but not yet verified, and therefore **not shipped**.
///
/// Nothing here is exported to the app. `sample_library.dart` holds what
/// users see; this file holds work in progress, and a test asserts the two
/// never overlap.
///
/// The reason for the split is the claim the product makes. Every shipped
/// prompt carries a verification date, a model label and a stated failure
/// boundary, and none of those can be filled in honestly for a prompt
/// nobody has run. So a draft has no `Freshness` at all — it is structurally
/// incapable of pretending to be verified — and promoting one means
/// actually running it. See `docs/verification-checklist.md`.
///
/// Syntax and limits below are researched from each vendor's own
/// documentation, with the source and date recorded per draft. Research
/// makes a prompt *plausible*, not *verified*.

/// A prompt awaiting verification.
class DraftVariant {
  /// Becomes the variant id once promoted.
  final String id;
  final String goalId;
  final String toolId;
  final String modelLabel;
  final String inputMethodId;
  final String title;
  final String summary;

  /// Where the syntax and limits came from, so the next person can re-check
  /// them when the tool changes.
  final String researchSource;
  final DateTime researchedOn;

  /// What the author must confirm by running it. These become guardrails
  /// once observed — until then they are claims from documentation, which
  /// is not the same thing.
  final List<String> toVerify;

  final List<PromptVariable> variables;
  final List<PromptStep> steps;

  const DraftVariant({
    required this.id,
    required this.goalId,
    required this.toolId,
    required this.modelLabel,
    required this.inputMethodId,
    required this.title,
    required this.summary,
    required this.researchSource,
    required this.researchedOn,
    required this.toVerify,
    required this.variables,
    required this.steps,
  });
}

/// Business-side goal, added under the "swap, don't stack" decision: the
/// deck category earns its place by having real depth, not by existing.
final List<Goal> draftGoals = [
  const Goal(
    id: 'goal_pitch_deck_from_notes',
    title: 'A pitch deck built from my rough notes',
    useCaseId: 'slide_deck_design',
    nicheIds: ['agency', 'saas'],
    outputTypeId: 'presentation',
    inputMethodIds: ['from_scratch'],
    summary:
        'Turns meeting notes or a scrappy outline into a structured deck '
        'with one idea per slide, then tightens it with follow-up edits.',
    inputContract: [
      ContractField(
        key: 'topic',
        type: VariableType.text,
        label: 'What the deck is about',
      ),
      ContractField(
        key: 'audience',
        type: VariableType.text,
        label: 'Who is in the room',
      ),
      ContractField(
        key: 'source_notes',
        type: VariableType.text,
        label: 'Your rough notes',
      ),
      ContractField(
        key: 'slide_count',
        type: VariableType.number,
        label: 'Slides',
      ),
      ContractField(
        key: 'tone',
        type: VariableType.enumChoice,
        label: 'Tone',
        options: ['Direct', 'Warm', 'Formal', 'Punchy'],
      ),
    ],
  ),
];

final List<DraftVariant> draftVariants = [
  // ---------------------------------------------------------------------
  DraftVariant(
    id: 'var_mj_oref_avatar',
    goalId: 'goal_consistent_avatar',
    toolId: 'midjourney',
    modelLabel: 'v7',
    inputMethodId: 'own_photo',
    title: 'Consistent character with Midjourney omni-reference',
    summary:
        'Holds one face across scenes using a hosted reference image, with '
        'the weight dialled for likeness without killing the style.',
    researchSource: 'https://updates.midjourney.com/omni-reference-oref/',
    researchedOn: DateTime(2026, 9, 20),
    toVerify: [
      'Does --ow 150 actually hold the face, or does this subject need more?',
      'At what --ow does the style stop responding? Docs warn above ~400; '
          'find the real number for this reference and write it down.',
      'Confirm the 2x GPU cost on the current plan before promising it.',
      'Run a second subject with different colouring — one lucky reference '
          'is not evidence.',
    ],
    variables: const [
      PromptVariable(
        key: 'subject_description',
        bindsTo: 'identity_name',
        type: VariableType.text,
        label: 'Who the character is',
        help:
            'Describe the person in words as well as giving the reference. '
            'At lower weights Midjourney leans on the text, so under-'
            'describing is what lets the face drift.',
        example: 'Mira, late 20s, short dark curls, warm olive skin',
        defaultValue: 'Mira, late 20s, short dark curls, warm olive skin',
        constraints: VariableConstraints(maxLength: 120),
      ),
      PromptVariable(
        key: 'reference_url',
        bindsTo: 'face_refs',
        type: VariableType.image,
        label: 'Reference image URL',
        help:
            'Must already be hosted somewhere public — --oref takes a URL, '
            'not an upload. One clear face, looking at the camera.',
        example: 'https://cdn.example.com/mira-ref.jpg',
      ),
      PromptVariable(
        key: 'scene',
        bindsTo: 'scene',
        type: VariableType.text,
        label: 'Outfit and setting',
        help: 'What they are wearing and where they are.',
        example: 'cream linen blazer, bright plant-filled studio',
        defaultValue: 'cream linen blazer, bright plant-filled studio',
      ),
      PromptVariable(
        key: 'omni_weight',
        type: VariableType.number,
        label: 'Likeness strength',
        help:
            'How hard the reference pulls. 0-1000, default 100. Low values '
            'stylise, high values copy. Midjourney warns that above roughly '
            '400 it fights --stylize and --exp and gets worse, not better.',
        example: '150',
        defaultValue: '150',
        constraints: VariableConstraints(min: 0, max: 1000),
      ),
      PromptVariable(
        key: 'aspect',
        bindsTo: 'aspect',
        type: VariableType.enumChoice,
        label: 'Aspect ratio',
        help: 'Frame shape.',
        example: '3:4',
        defaultValue: '3:4',
        options: ['1:1', '3:4', '9:16', '16:9'],
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Host the reference image',
        toolId: 'midjourney',
        actionType: StepActionType.upload,
        where: 'Any public host — Discord upload, Drive share link, S3',
        inputs: [StepInput.variable('reference_url', label: 'Reference')],
        produces: StepOutput(
          id: 'hosted_reference',
          label: 'A public image URL',
          type: 'url',
        ),
        expectedOutput: 'A URL that loads the face without a login.',
        guardrails: [
          '--oref takes a URL, not a file. A private or expiring link fails '
              'silently and you get a generic face instead of an error.',
        ],
        estMinutes: 2,
      ),
      PromptStep(
        order: 2,
        title: 'Generate with omni-reference',
        toolId: 'midjourney',
        modelLabel: 'v7',
        actionType: StepActionType.prompt,
        prompt:
            '{{subject_description}}, {{scene}}, soft window light, 50mm '
            'portrait --oref {{reference_url}} --ow {{omni_weight}} '
            '--ar {{aspect}} --v 7',
        inputs: [
          StepInput.fromStep('hosted_reference', label: 'Reference URL'),
        ],
        produces: StepOutput(
          id: 'portrait_set',
          label: 'Portrait variations',
          type: 'image[]',
        ),
        expectedOutput: 'Four images holding the same face in the new scene.',
        guardrails: [
          'Omni-reference costs 2x GPU time and does not work in Fast, Draft '
              'or Conversational mode, or with --q 4.',
          'Multiple people in one reference image is documented as barely '
              'tested — use one face.',
        ],
        estMinutes: 3,
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  DraftVariant(
    id: 'var_gamma_deck_from_notes',
    goalId: 'goal_pitch_deck_from_notes',
    toolId: 'gamma',
    modelLabel: 'Gamma 3',
    inputMethodId: 'from_scratch',
    title: 'Pitch deck from rough notes with Gamma',
    summary:
        'Generates a structured deck from notes, then fixes structure with '
        'follow-up commands rather than regenerating from scratch.',
    researchSource:
        'https://gamma.app/explore/content/guides/'
        'the-ultimate-guide-to-ai-presentation-prompts-how-to-get-better-'
        'slides-from-gamma',
    researchedOn: DateTime(2026, 9, 20),
    toVerify: [
      'Confirm the free tier still caps generation at 10 cards — the pitch '
          'depends on it and tiers change.',
      'Does the refinement command actually reorder, or silently rewrite? '
          'Run "Reorder to problem, insight, recommendation, next steps".',
      'Try it with genuinely messy notes, not a tidy outline. Tidy input '
          'proves nothing about the prompt.',
    ],
    variables: const [
      PromptVariable(
        key: 'topic',
        bindsTo: 'topic',
        type: VariableType.text,
        label: 'What the deck is about',
        help: 'One line. The deck is built around this.',
        example: 'Why we should move our support tooling in-house',
        defaultValue: 'Why we should move our support tooling in-house',
      ),
      PromptVariable(
        key: 'audience',
        bindsTo: 'audience',
        type: VariableType.text,
        label: 'Who is in the room',
        help:
            'Naming the audience changes the vocabulary more than any other '
            'instruction. "The board" and "the engineering team" get very '
            'different decks.',
        example: 'our COO and head of support, neither technical',
        defaultValue: 'our COO and head of support, neither technical',
      ),
      PromptVariable(
        key: 'source_notes',
        bindsTo: 'source_notes',
        type: VariableType.text,
        label: 'Your rough notes',
        help:
            'Paste them raw. Gamma produces generic decks from thin prompts, '
            'so the notes are the difference between your deck and anyone '
            'else\'s.',
        example:
            'vendor renewal is 40k, up 30%. we only use 3 of 11 features. '
            'two engineers say a basic version is ~6 weeks…',
      ),
      PromptVariable(
        key: 'slide_count',
        bindsTo: 'slide_count',
        type: VariableType.number,
        label: 'Slides',
        help:
            'Free workspaces cap a generation at 10 cards; paid go to 100. '
            'Ask for fewer than you think — density is the usual failure.',
        example: '8',
        defaultValue: '8',
        constraints: VariableConstraints(min: 3, max: 100),
      ),
      PromptVariable(
        key: 'tone',
        bindsTo: 'tone',
        type: VariableType.enumChoice,
        label: 'Tone',
        help: 'Sets register, not content.',
        example: 'Direct',
        defaultValue: 'Direct',
        options: ['Direct', 'Warm', 'Formal', 'Punchy'],
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Generate the deck',
        toolId: 'gamma',
        modelLabel: 'Gamma 3',
        actionType: StepActionType.prompt,
        prompt:
            'Build a {{slide_count}}-slide deck arguing: {{topic}}.\n'
            'Audience: {{audience}}. Tone: {{tone}}.\n'
            'One idea per slide. Lead with the recommendation, then the '
            'evidence, then what happens next. No slide with more than 30 '
            'words of body text.\n\n'
            'Work only from these notes — do not invent figures:\n'
            '{{source_notes}}',
        settings: {'num_cards': '{{slide_count}}', 'tone': '{{tone}}'},
        produces: StepOutput(
          id: 'draft_deck',
          label: 'Generated deck',
          type: 'deck',
        ),
        expectedOutput:
            'A structured deck in 30-60 seconds, one idea per card.',
        guardrails: [
          'Thin prompts produce generic decks. If the notes are one line, '
              'the deck will read like anyone\'s.',
          '"Do not invent figures" matters: without it, plausible numbers '
              'appear that you will have to defend in the room.',
        ],
        estMinutes: 2,
      ),
      PromptStep(
        order: 2,
        title: 'Fix the structure, do not regenerate',
        toolId: 'gamma',
        actionType: StepActionType.prompt,
        prompt:
            'Reorder the deck to follow: problem, insight, recommendation, '
            'next steps. Then flag any slide that is too dense and split it.',
        inputs: [StepInput.fromStep('draft_deck', label: 'The draft deck')],
        produces: StepOutput(
          id: 'tightened_deck',
          label: 'Restructured deck',
          type: 'deck',
        ),
        expectedOutput: 'The same content, in an order that argues.',
        guardrails: [
          'Regenerating loses edits. Structural commands change the existing '
              'deck; a new generation starts over.',
        ],
        estMinutes: 3,
      ),
      PromptStep(
        order: 3,
        title: 'Check every number against your notes',
        toolId: 'gamma',
        actionType: StepActionType.export,
        where: 'Read the deck beside the source notes, then Export → PDF',
        inputs: [StepInput.fromStep('tightened_deck', label: 'Final deck')],
        produces: StepOutput(
          id: 'final_deck',
          label: 'Exported deck',
          type: 'file',
        ),
        expectedOutput: 'A deck whose every figure traces to your notes.',
        guardrails: [
          'This step is not optional. Generated decks produce confident '
              'figures that were never in the source.',
        ],
        estMinutes: 5,
      ),
    ],
  ),
];
