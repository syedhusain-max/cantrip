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
  const Goal(
    id: 'goal_product_hero_shot',
    title: 'A product photo good enough to be the hero image',
    useCaseId: 'product_photography',
    nicheIds: ['ecommerce', 'agency'],
    outputTypeId: 'image',
    inputMethodIds: ['own_photo'],
    summary:
        'Takes a plain product photo and puts it in a lit, styled scene that '
        'holds the real object rather than inventing a similar one.',
    inputContract: [
      ContractField(
        key: 'product_photo',
        type: VariableType.image,
        label: 'Your product photo',
      ),
      ContractField(
        key: 'product_name',
        type: VariableType.text,
        label: 'What the product is',
      ),
      ContractField(
        key: 'setting',
        type: VariableType.text,
        label: 'Scene and surface',
      ),
      ContractField(
        key: 'lighting',
        type: VariableType.enumChoice,
        label: 'Lighting',
        options: [
          'Soft window light',
          'Hard studio key',
          'Golden hour',
          'Moody low key',
        ],
      ),
      ContractField(
        key: 'aspect',
        type: VariableType.enumChoice,
        label: 'Aspect ratio',
        options: ['1:1', '4:5', '3:4', '16:9'],
      ),
    ],
  ),
  const Goal(
    id: 'goal_campaign_style_lock',
    title: 'One visual style held across a whole campaign',
    useCaseId: 'brand_design',
    nicheIds: ['agency', 'ecommerce', 'saas'],
    outputTypeId: 'image',
    inputMethodIds: ['from_scratch', 'own_photo'],
    summary:
        'Locks a look — colour, grain, lighting, medium — so twenty images '
        'made on different days still read as one campaign.',
    inputContract: [
      ContractField(
        key: 'style_anchor',
        type: VariableType.text,
        label: 'Style code or reference image',
      ),
      ContractField(
        key: 'subject',
        type: VariableType.text,
        label: 'What is in this frame',
      ),
      ContractField(
        key: 'style_strength',
        type: VariableType.number,
        label: 'How hard to hold the style',
      ),
      ContractField(
        key: 'aspect',
        type: VariableType.enumChoice,
        label: 'Aspect ratio',
        options: ['1:1', '4:5', '3:4', '16:9'],
      ),
    ],
  ),
  const Goal(
    id: 'goal_board_update_doc',
    title: 'A monthly board update nobody has to decode',
    useCaseId: 'pdf_document_design',
    nicheIds: ['saas', 'agency', 'consulting'],
    outputTypeId: 'document',
    inputMethodIds: ['from_my_content'],
    summary:
        'Turns the month\'s numbers and notes into a document that leads '
        'with what changed and what you need from the reader.',
    inputContract: [
      ContractField(
        key: 'period',
        type: VariableType.text,
        label: 'Which month',
      ),
      ContractField(
        key: 'audience',
        type: VariableType.text,
        label: 'Who reads it',
      ),
      ContractField(
        key: 'source_notes',
        type: VariableType.text,
        label: 'Numbers and notes',
      ),
      ContractField(
        key: 'asks',
        type: VariableType.text,
        label: 'What you need from them',
      ),
      ContractField(
        key: 'tone',
        type: VariableType.enumChoice,
        label: 'Tone',
        options: ['Direct', 'Warm', 'Formal', 'Punchy'],
      ),
    ],
  ),
  const Goal(
    id: 'goal_launch_page',
    title: 'A one-page site for a launch, live the same afternoon',
    useCaseId: 'motion_web_design',
    nicheIds: ['saas', 'agency'],
    outputTypeId: 'webpage',
    inputMethodIds: ['from_scratch'],
    summary:
        'A single page that says what the thing is, who it is for and what '
        'to do next — structured before it is decorated.',
    inputContract: [
      ContractField(
        key: 'product_name',
        type: VariableType.text,
        label: 'What you are launching',
      ),
      ContractField(
        key: 'audience',
        type: VariableType.text,
        label: 'Who it is for',
      ),
      ContractField(
        key: 'source_notes',
        type: VariableType.text,
        label: 'What it does, in your words',
      ),
      ContractField(
        key: 'call_to_action',
        type: VariableType.text,
        label: 'The one action you want',
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

  // ---------------------------------------------------------------------
  // Product hero shot, written for two tools against one goal. This pair
  // is what the tool switcher exists to demonstrate: the same product,
  // the same scene, carried across by bindsTo, rendered in each tool's
  // own syntax.
  DraftVariant(
    id: 'var_mj_product_hero',
    goalId: 'goal_product_hero_shot',
    toolId: 'midjourney',
    modelLabel: 'v7',
    inputMethodId: 'own_photo',
    title: 'Product hero shot with Midjourney omni-reference',
    summary:
        'Puts your actual product into a styled scene instead of generating '
        'something that merely resembles it.',
    researchSource: 'https://updates.midjourney.com/omni-reference-oref/',
    researchedOn: DateTime(2026, 9, 20),
    toVerify: [
      'Does --ow 400 keep label text legible, or does it still garble? '
          'Product shots live or die on the label.',
      'Compare against a plain --sref run: if the reference is not clearly '
          'holding the object, this prompt has no reason to exist.',
      'Run a second product with a different shape — bottles behave '
          'differently from boxes.',
    ],
    variables: const [
      PromptVariable(
        key: 'reference_url',
        bindsTo: 'product_photo',
        type: VariableType.image,
        label: 'Product photo URL',
        help:
            'Hosted, public, one product, plain background. --oref takes a '
            'URL rather than an upload.',
        example: 'https://cdn.example.com/bottle-front.jpg',
      ),
      PromptVariable(
        key: 'product_name',
        bindsTo: 'product_name',
        type: VariableType.text,
        label: 'What the product is',
        help:
            'Name the object plainly. The text still steers composition even '
            'when the reference is doing the identity work.',
        example: 'a matte black 500ml water bottle',
        defaultValue: 'a matte black 500ml water bottle',
      ),
      PromptVariable(
        key: 'setting',
        bindsTo: 'setting',
        type: VariableType.text,
        label: 'Scene and surface',
        help: 'Where it sits and what it sits on.',
        example: 'on pale travertine, eucalyptus shadow across the frame',
        defaultValue: 'on pale travertine, eucalyptus shadow across the frame',
      ),
      PromptVariable(
        key: 'lighting',
        bindsTo: 'lighting',
        type: VariableType.enumChoice,
        label: 'Lighting',
        help: 'The single biggest lever on whether it reads as a real photo.',
        example: 'Soft window light',
        defaultValue: 'Soft window light',
        options: [
          'Soft window light',
          'Hard studio key',
          'Golden hour',
          'Moody low key',
        ],
      ),
      PromptVariable(
        key: 'omni_weight',
        type: VariableType.number,
        label: 'Product fidelity',
        help:
            '0-1000, default 100. Products need more than faces do — the '
            'shape and label have to survive. Start around 400 and only go '
            'higher if the object is still drifting.',
        example: '400',
        defaultValue: '400',
        constraints: VariableConstraints(min: 0, max: 1000),
      ),
      PromptVariable(
        key: 'aspect',
        bindsTo: 'aspect',
        type: VariableType.enumChoice,
        label: 'Aspect ratio',
        help: '4:5 for feed, 1:1 for listings, 16:9 for banners.',
        example: '4:5',
        defaultValue: '4:5',
        options: ['1:1', '4:5', '3:4', '16:9'],
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Host the product photo',
        toolId: 'midjourney',
        actionType: StepActionType.upload,
        where: 'Any public host — Discord upload, Drive share link, S3',
        inputs: [StepInput.variable('reference_url', label: 'Product photo')],
        produces: StepOutput(
          id: 'hosted_product',
          label: 'Public image URL',
          type: 'url',
        ),
        expectedOutput: 'A URL that loads the product without a login.',
        guardrails: [
          'Shoot or crop to one product on a plain background first. A busy '
              'source photo gives the reference two subjects to reconcile.',
        ],
        estMinutes: 3,
      ),
      PromptStep(
        order: 2,
        title: 'Generate the hero frames',
        toolId: 'midjourney',
        modelLabel: 'v7',
        actionType: StepActionType.prompt,
        prompt:
            'product photograph of {{product_name}}, {{setting}}, '
            '{{lighting}}, shallow depth of field, commercial still life '
            '--oref {{reference_url}} --ow {{omni_weight}} --ar {{aspect}} '
            '--v 7',
        inputs: [StepInput.fromStep('hosted_product', label: 'Product URL')],
        produces: StepOutput(
          id: 'hero_frames',
          label: 'Hero candidates',
          type: 'image[]',
        ),
        expectedOutput: 'Four frames of the real product in the styled scene.',
        guardrails: [
          'Omni-reference costs 2x GPU time and is unavailable in Fast, '
              'Draft and Conversational modes and with --q 4.',
          'Text on packaging is the first thing to break. Check the label '
              'at full size before shortlisting a frame.',
        ],
        estMinutes: 4,
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  DraftVariant(
    id: 'var_oa_product_hero',
    goalId: 'goal_product_hero_shot',
    toolId: 'openart',
    modelLabel: 'Character 2.0',
    inputMethodId: 'own_photo',
    title: 'Product hero shot with an OpenArt trained object',
    summary:
        'Trains the product as a reusable character so repeat shoots stay '
        'identical, rather than re-uploading a reference every time.',
    researchSource: 'https://openart.ai/whats-new',
    researchedOn: DateTime(2026, 9, 20),
    toVerify: [
      'Confirm the current minimum training images — documentation says '
          '4-20, and the floor moves between releases.',
      'Does object training hold a printed label, or only silhouette and '
          'colour? This decides whether the variant is honest for packaging.',
      'Check whether the trigger word needs to lead the prompt or can sit '
          'mid-sentence.',
    ],
    variables: const [
      PromptVariable(
        key: 'training_images',
        bindsTo: 'product_photo',
        type: VariableType.imageList,
        label: 'Product photos',
        help:
            'Several angles of the same object, even lighting, plain '
            'background. Small variations in angle train better than '
            'identical repeats.',
        example: 'bottle_front.jpg … bottle_side.jpg',
        constraints: VariableConstraints(minItems: 4, maxItems: 20),
      ),
      PromptVariable(
        key: 'trigger_word',
        bindsTo: 'product_name',
        type: VariableType.text,
        label: 'Trigger word',
        help:
            'A short unique token that summons the trained object. Invent '
            'one — a real word competes with what the model already knows.',
        example: 'nordbottle',
        defaultValue: 'nordbottle',
        constraints: VariableConstraints(maxLength: 24),
      ),
      PromptVariable(
        key: 'setting',
        bindsTo: 'setting',
        type: VariableType.text,
        label: 'Scene and surface',
        help: 'Where it sits and what it sits on.',
        example: 'on pale travertine, eucalyptus shadow across the frame',
        defaultValue: 'on pale travertine, eucalyptus shadow across the frame',
      ),
      PromptVariable(
        key: 'lighting',
        bindsTo: 'lighting',
        type: VariableType.enumChoice,
        label: 'Lighting',
        help: 'Carried over if you arrived here from another tool.',
        example: 'Soft window light',
        defaultValue: 'Soft window light',
        options: [
          'Soft window light',
          'Hard studio key',
          'Golden hour',
          'Moody low key',
        ],
      ),
      PromptVariable(
        key: 'aspect',
        bindsTo: 'aspect',
        type: VariableType.enumChoice,
        label: 'Aspect ratio',
        help: 'Frame shape.',
        example: '4:5',
        defaultValue: '4:5',
        options: ['1:1', '4:5', '3:4', '16:9'],
      ),
      PromptVariable(
        key: 'avoid',
        type: VariableType.text,
        label: 'Keep out of frame',
        help: 'Negative prompt. Hands and reflections are the usual spoilers.',
        example: 'hands, text overlay, harsh reflections, cluttered props',
        defaultValue: 'hands, text overlay, harsh reflections, cluttered props',
        required: false,
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Train the product as a character',
        toolId: 'openart',
        actionType: StepActionType.upload,
        where: 'OpenArt → Characters → Train → type: object',
        inputs: [
          StepInput.variable('training_images', label: 'Product photos'),
          StepInput.variable('trigger_word', label: 'Trigger word'),
        ],
        produces: StepOutput(
          id: 'trained_object',
          label: 'Trained product, callable by its trigger word',
          type: 'tool_artifact',
        ),
        expectedOutput:
            'A trained model that reproduces the product on demand.',
        guardrails: [
          'Photos from one angle train a flat object: it will look right '
              'head-on and wrong everywhere else.',
        ],
        estMinutes: 12,
      ),
      PromptStep(
        order: 2,
        title: 'Shoot the scene',
        toolId: 'openart',
        modelLabel: 'Character 2.0',
        actionType: StepActionType.prompt,
        prompt:
            '{{trigger_word}}, product photograph, {{setting}}, {{lighting}}, '
            'shallow depth of field, commercial still life',
        negativePrompt: '{{avoid}}',
        settings: {
          'aspect_ratio': '{{aspect}}',
          'character': '{{trigger_word}}',
        },
        inputs: [
          StepInput.fromStep('trained_object', label: 'Trained product'),
        ],
        produces: StepOutput(
          id: 'hero_frames',
          label: 'Hero candidates',
          type: 'image[]',
        ),
        expectedOutput: 'Frames holding the trained product in the scene.',
        guardrails: [
          'Lead with the trigger word. Buried mid-prompt it competes with '
              'the scene description and the object drifts.',
        ],
        estMinutes: 3,
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  DraftVariant(
    id: 'var_mj_style_lock',
    goalId: 'goal_campaign_style_lock',
    toolId: 'midjourney',
    modelLabel: 'v7',
    inputMethodId: 'from_scratch',
    title: 'Campaign style lock with Midjourney style references',
    summary:
        'Holds one look across a whole set using a style code, so images '
        'made weeks apart still belong together.',
    researchSource:
        'https://docs.midjourney.com/hc/en-us/articles/'
        '32180011136653-Style-Reference',
    researchedOn: DateTime(2026, 9, 20),
    toVerify: [
      'Find a style code worth keeping and record it — the whole variant '
          'depends on having one, and --sref random is not a campaign.',
      'Check whether --sw 100 is enough to hold the look across very '
          'different subjects, or whether it needs raising per subject.',
      'Confirm the documented claim that style weight bites harder with '
          'codes than with reference images.',
    ],
    variables: const [
      PromptVariable(
        key: 'style_code',
        bindsTo: 'style_anchor',
        type: VariableType.text,
        label: 'Style code or reference URL',
        help:
            'A numeric style code (e.g. 2213253170) or a hosted image URL. '
            'Codes are more repeatable; write yours down, because a style '
            'you cannot reproduce is not a campaign style.',
        example: '2213253170',
        defaultValue: '2213253170',
      ),
      PromptVariable(
        key: 'subject',
        bindsTo: 'subject',
        type: VariableType.text,
        label: 'What is in this frame',
        help:
            'The only thing that changes between images in the set. Keep '
            'everything else identical and the campaign holds together.',
        example: 'a ceramic mug on a linen cloth',
        defaultValue: 'a ceramic mug on a linen cloth',
      ),
      PromptVariable(
        key: 'style_weight',
        bindsTo: 'style_strength',
        type: VariableType.number,
        label: 'Style strength',
        help:
            '0-1000, default 100. 0 ignores the reference entirely; 1000 '
            'follows it very closely at the cost of your subject.',
        example: '100',
        defaultValue: '100',
        constraints: VariableConstraints(min: 0, max: 1000),
      ),
      PromptVariable(
        key: 'aspect',
        bindsTo: 'aspect',
        type: VariableType.enumChoice,
        label: 'Aspect ratio',
        help: 'Keep this constant across the set.',
        example: '4:5',
        defaultValue: '4:5',
        options: ['1:1', '4:5', '3:4', '16:9'],
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Render one frame of the set',
        toolId: 'midjourney',
        modelLabel: 'v7',
        actionType: StepActionType.prompt,
        prompt:
            '{{subject}} --sref {{style_code}} --sw {{style_weight}} '
            '--ar {{aspect}} --v 7',
        produces: StepOutput(
          id: 'styled_frame',
          label: 'One image in the campaign style',
          type: 'image[]',
        ),
        expectedOutput:
            'A frame whose colour, grain and lighting match the rest of the '
            'set, whatever the subject.',
        guardrails: [
          'A style reference carries mood, colour and medium — not objects. '
              'If you need the same object, that is omni-reference, not this.',
          'Changing the subject wording heavily will pull the look with it. '
              'Change the subject, not the style adjectives.',
        ],
        estMinutes: 3,
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  DraftVariant(
    id: 'var_gamma_board_update',
    goalId: 'goal_board_update_doc',
    toolId: 'gamma',
    modelLabel: 'Gamma 3',
    inputMethodId: 'from_my_content',
    title: 'Monthly board update as a Gamma document',
    summary:
        'A document, not a deck: prose the reader can skim in five minutes, '
        'leading with what changed and what you need.',
    researchSource:
        'https://help.gamma.app/en/articles/'
        '7838093-how-do-i-create-a-new-presentation-document-or-webpage-in-gamma',
    researchedOn: DateTime(2026, 9, 20),
    toVerify: [
      'Confirm the document format keeps prose rather than collapsing into '
          'slide-style bullets — the whole point of this variant.',
      'Test with a month that went badly. Generators tend to smooth bad '
          'news, and a board update that hides it is worse than none.',
      'Check that every figure in the output traces to the source notes.',
    ],
    variables: const [
      PromptVariable(
        key: 'period',
        bindsTo: 'period',
        type: VariableType.text,
        label: 'Which month',
        help: 'Named explicitly so the document dates itself.',
        example: 'August 2026',
        defaultValue: 'August 2026',
      ),
      PromptVariable(
        key: 'audience',
        bindsTo: 'audience',
        type: VariableType.text,
        label: 'Who reads it',
        help: 'Changes vocabulary more than any other instruction.',
        example: 'three board members, one technical',
        defaultValue: 'three board members, one technical',
      ),
      PromptVariable(
        key: 'source_notes',
        bindsTo: 'source_notes',
        type: VariableType.text,
        label: 'Numbers and notes',
        help:
            'Paste raw. Revenue, churn, headcount, what shipped, what '
            'slipped. Thin input produces a confident, empty document.',
        example:
            'MRR 41k up from 38k. two churned, both under 6 months. '
            'hired one engineer. billing rewrite slipped two weeks…',
      ),
      PromptVariable(
        key: 'asks',
        bindsTo: 'asks',
        type: VariableType.text,
        label: 'What you need from them',
        help:
            'The reason the document exists. Without it a board update is '
            'just reporting.',
        example: 'an intro to two logistics buyers, and sign-off on the hire',
        defaultValue:
            'an intro to two logistics buyers, and sign-off on the hire',
      ),
      PromptVariable(
        key: 'tone',
        bindsTo: 'tone',
        type: VariableType.enumChoice,
        label: 'Tone',
        help: 'Register only. It should not soften bad numbers.',
        example: 'Direct',
        defaultValue: 'Direct',
        options: ['Direct', 'Warm', 'Formal', 'Punchy'],
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Generate the document',
        toolId: 'gamma',
        modelLabel: 'Gamma 3',
        actionType: StepActionType.prompt,
        prompt:
            'Write a board update for {{period}}, as a document in prose, '
            'not slides.\n'
            'Readers: {{audience}}. Tone: {{tone}}.\n'
            'Open with the three things that changed this month, worst news '
            'first. Then the numbers with their deltas. End with what I need '
            'from the reader: {{asks}}.\n'
            'Use only these notes. Do not invent figures, and do not soften '
            'anything that went badly:\n'
            '{{source_notes}}',
        settings: {'format': 'document', 'tone': '{{tone}}'},
        produces: StepOutput(
          id: 'draft_update',
          label: 'Generated document',
          type: 'document',
        ),
        expectedOutput:
            'A skimmable update that leads with change, not with context.',
        guardrails: [
          '"Worst news first" is doing real work. Left to itself the output '
              'buries the bad month in the middle where nobody reads it.',
        ],
        estMinutes: 3,
      ),
      PromptStep(
        order: 2,
        title: 'Check every number, then send',
        toolId: 'gamma',
        actionType: StepActionType.export,
        where: 'Read beside your notes, then Share → PDF or link',
        inputs: [StepInput.fromStep('draft_update', label: 'The document')],
        produces: StepOutput(
          id: 'final_update',
          label: 'Sent update',
          type: 'file',
        ),
        expectedOutput: 'An update whose every figure traces to your notes.',
        guardrails: [
          'Not optional. A board update with an invented number costs more '
              'than the hour it saved.',
        ],
        estMinutes: 8,
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  DraftVariant(
    id: 'var_gamma_launch_page',
    goalId: 'goal_launch_page',
    toolId: 'gamma',
    modelLabel: 'Gamma 3',
    inputMethodId: 'from_scratch',
    title: 'One-page launch site with Gamma',
    summary:
        'A single page structured around one action, generated as a website '
        'rather than a deck reshaped into one.',
    researchSource:
        'https://gamma.app/explore/content/guides/'
        'gamma-platform-presentations-documents-web-pages',
    researchedOn: DateTime(2026, 9, 20),
    toVerify: [
      'Confirm the website format produces a real page structure rather '
          'than stacked slides.',
      'Check what the published URL looks like and whether a custom domain '
          'is available on the tier you are on.',
      'Regenerate once and see whether edits survive — if not, say so, '
          'because people will lose work to it.',
    ],
    variables: const [
      PromptVariable(
        key: 'product_name',
        bindsTo: 'product_name',
        type: VariableType.text,
        label: 'What you are launching',
        help: 'The name, as it should appear on the page.',
        example: 'Cantrip',
        defaultValue: 'Cantrip',
      ),
      PromptVariable(
        key: 'audience',
        bindsTo: 'audience',
        type: VariableType.text,
        label: 'Who it is for',
        help:
            'Specific beats broad. "Freelance designers billing clients" '
            'writes a better page than "creators".',
        example: 'freelancers using AI tools on client work',
        defaultValue: 'freelancers using AI tools on client work',
      ),
      PromptVariable(
        key: 'source_notes',
        bindsTo: 'source_notes',
        type: VariableType.text,
        label: 'What it does, in your words',
        help: 'Plain sentences. The page is only as concrete as this is.',
        example:
            'library of tested prompts for AI tools. every prompt says when '
            'it was last checked and on which model…',
      ),
      PromptVariable(
        key: 'call_to_action',
        bindsTo: 'call_to_action',
        type: VariableType.text,
        label: 'The one action',
        help: 'One. A page with three equal calls to action has none.',
        example: 'Open the library',
        defaultValue: 'Open the library',
      ),
      PromptVariable(
        key: 'tone',
        bindsTo: 'tone',
        type: VariableType.enumChoice,
        label: 'Tone',
        help: 'Register of the copy.',
        example: 'Direct',
        defaultValue: 'Direct',
        options: ['Direct', 'Warm', 'Formal', 'Punchy'],
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Generate the page',
        toolId: 'gamma',
        modelLabel: 'Gamma 3',
        actionType: StepActionType.prompt,
        prompt:
            'Build a one-page website for {{product_name}}, for '
            '{{audience}}. Tone: {{tone}}.\n'
            'Structure: what it is in one line, the problem it removes, '
            'three things it does, what it costs, then "{{call_to_action}}" '
            'as the only action on the page.\n'
            'No testimonials, no invented statistics, no logos of companies '
            'that have not used it.\n\n'
            'Source material:\n{{source_notes}}',
        settings: {'format': 'website', 'tone': '{{tone}}'},
        produces: StepOutput(
          id: 'draft_page',
          label: 'Generated page',
          type: 'webpage',
        ),
        expectedOutput: 'A structured one-page site with a single action.',
        guardrails: [
          'The "no testimonials, no invented statistics" line is load '
              'bearing. Generators fill social proof with fiction, and a '
              'fake quote on a launch page is the kind of thing screenshots '
              'outlive.',
        ],
        estMinutes: 3,
      ),
      PromptStep(
        order: 2,
        title: 'Cut it down, then publish',
        toolId: 'gamma',
        actionType: StepActionType.export,
        where: 'Edit in place, then Share → Publish',
        inputs: [StepInput.fromStep('draft_page', label: 'The page')],
        produces: StepOutput(
          id: 'published_page',
          label: 'Live URL',
          type: 'url',
        ),
        expectedOutput: 'A live page you can send to someone.',
        guardrails: [
          'First drafts run long. Delete whole sections rather than '
              'shortening every sentence — a page that scrolls twice is read '
              'once.',
        ],
        estMinutes: 15,
      ),
    ],
  ),
];
