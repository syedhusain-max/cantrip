import '../models/freshness.dart';
import '../models/gallery_asset.dart';
import '../models/goal.dart';
import '../models/prompt_step.dart';
import '../models/prompt_variable.dart';
import '../models/prompt_variant.dart';

/// The seeded library: 7 goals, 8 variants, written as a best effort in
/// each tool's native syntax.
///
/// This is the only file that changes to replace the samples with real
/// content or to add prompts for a new tool. Per the build plan the content
/// ships inside the app bundle rather than behind an API — 8 entries (or
/// the 20 the plan targets for launch) is a few hundred KB, so a content
/// API would be cost and latency for nothing.
///
/// Every variant carries at least one guardrail: the publish gate treats an
/// author who can't name a failure mode as not having tested enough.

const List<Goal> sampleGoals = [
  Goal(
    id: 'goal_consistent_avatar',
    title: 'A consistent AI avatar I can reuse across scenes',
    useCaseId: 'avatar_creation',
    nicheIds: ['ecommerce', 'fitness'],
    outputTypeId: 'image',
    inputMethodIds: ['own_photo', 'from_scratch'],
    summary:
        'One identity that stays recognisably the same person across outfits, '
        'lighting and scenes — the basis for a virtual model or spokesperson.',
    inputContract: [
      ContractField(
        key: 'identity_name',
        type: VariableType.text,
        label: 'Character name',
      ),
      ContractField(
        key: 'face_refs',
        type: VariableType.imageList,
        label: 'Face references',
      ),
      ContractField(
        key: 'scene',
        type: VariableType.text,
        label: 'Outfit and setting',
      ),
      ContractField(
        key: 'aspect',
        type: VariableType.enumChoice,
        label: 'Aspect ratio',
        options: ['1:1', '3:4', '9:16'],
      ),
    ],
  ),
  Goal(
    id: 'goal_animated_landing',
    title: 'An animated one-page site that does not look AI-generated',
    useCaseId: 'motion_web_design',
    nicheIds: ['agency'],
    outputTypeId: 'webpage',
    inputMethodIds: ['from_scratch'],
    summary:
        'A single responsive page with restrained, purposeful motion — scroll '
        'reveals and hover states that serve the content instead of decorating it.',
    inputContract: [
      ContractField(
        key: 'brand_name',
        type: VariableType.text,
        label: 'Brand name',
      ),
      ContractField(
        key: 'headline',
        type: VariableType.text,
        label: 'Hero headline',
      ),
      ContractField(
        key: 'primary_color',
        type: VariableType.color,
        label: 'Primary colour',
      ),
    ],
  ),
  Goal(
    id: 'goal_agency_landing_copy',
    title: 'Structured landing page copy for an agency',
    useCaseId: 'brand_design',
    nicheIds: ['real_estate', 'agency'],
    outputTypeId: 'webpage',
    inputMethodIds: ['from_scratch'],
    summary:
        'Section-by-section outline plus final copy and SEO metadata, ready to '
        'hand to a designer or paste into a page builder.',
    inputContract: [
      ContractField(
        key: 'brand_name',
        type: VariableType.text,
        label: 'Agency name',
      ),
      ContractField(
        key: 'region',
        type: VariableType.text,
        label: 'Service area',
      ),
    ],
  ),
  Goal(
    id: 'goal_ugc_social_video',
    title: 'A short talking-avatar video for social',
    useCaseId: 'social_media_video',
    nicheIds: ['ecommerce'],
    outputTypeId: 'video',
    inputMethodIds: ['own_photo'],
    summary:
        'A vertical, captioned clip where a presenter delivers a tight script — '
        'the format that carries product launches on TikTok and Reels.',
    inputContract: [
      ContractField(
        key: 'product_name',
        type: VariableType.text,
        label: 'Product',
      ),
      ContractField(
        key: 'face_refs',
        type: VariableType.imageList,
        label: 'Presenter photo',
      ),
      ContractField(
        key: 'cta',
        type: VariableType.text,
        label: 'Call to action',
      ),
    ],
  ),
  Goal(
    id: 'goal_product_turntable',
    title: 'A product photo turned into a short showcase video',
    useCaseId: 'product_photography',
    nicheIds: ['ecommerce'],
    outputTypeId: 'video',
    inputMethodIds: ['own_photo'],
    summary:
        'One clean studio still becomes a seamless looping clip for listings '
        'and paid social, without a studio booking.',
    inputContract: [
      ContractField(
        key: 'product_name',
        type: VariableType.text,
        label: 'Product',
      ),
      ContractField(
        key: 'product_shot',
        type: VariableType.image,
        label: 'Product photo',
      ),
    ],
  ),
  Goal(
    id: 'goal_starter_brand_kit',
    title: 'A starter brand kit: logo, palette, voice and templates',
    useCaseId: 'logo_brand_kit',
    nicheIds: ['agency'],
    outputTypeId: 'brand_kit',
    inputMethodIds: ['from_template'],
    summary:
        'From a name and a few adjectives to a small usable kit. Deliberately '
        'tool-agnostic: each step suggests tools rather than requiring one.',
    inputContract: [
      ContractField(
        key: 'brand_name',
        type: VariableType.text,
        label: 'Brand name',
      ),
      ContractField(
        key: 'style_keywords',
        type: VariableType.text,
        label: 'Style keywords',
      ),
      ContractField(
        key: 'primary_color',
        type: VariableType.color,
        label: 'Primary colour',
      ),
    ],
  ),
  Goal(
    id: 'goal_realestate_brand_kit',
    title: 'A brand kit for a local real estate agency',
    useCaseId: 'logo_brand_kit',
    nicheIds: ['real_estate'],
    outputTypeId: 'brand_kit',
    inputMethodIds: ['from_scratch'],
    summary:
        'A focused two-tool run: a logo mark, then a written guideline that '
        'ties the mark, palette, type and taglines together.',
    inputContract: [
      ContractField(
        key: 'brand_name',
        type: VariableType.text,
        label: 'Agency name',
      ),
      ContractField(
        key: 'style_keywords',
        type: VariableType.text,
        label: 'Style keywords',
      ),
      ContractField(
        key: 'primary_color',
        type: VariableType.color,
        label: 'Primary colour',
      ),
    ],
  ),
];

final List<PromptVariant> sampleVariants = [
  // ---------------------------------------------------------------------
  // goal_consistent_avatar — variant A: Higgsfield, from the user's photos
  // ---------------------------------------------------------------------
  PromptVariant(
    id: 'var_hgf_soulid',
    goalId: 'goal_consistent_avatar',
    toolId: 'higgsfield',
    modelLabel: 'Soul 2.0',
    inputMethodId: 'own_photo',
    title: 'SAMPLE: Consistent avatar with Higgsfield Soul ID',
    summary:
        'Trains a reusable identity from your own photos, then generates '
        'on-model portraits from it.',
    variables: const [
      PromptVariable(
        key: 'character_name',
        bindsTo: 'identity_name',
        type: VariableType.text,
        label: 'Character name',
        help: 'Names the Soul ID and becomes the handle used in every later step.',
        example: 'Mira',
        defaultValue: 'Mira',
        constraints: VariableConstraints(maxLength: 32),
      ),
      PromptVariable(
        key: 'reference_photos',
        bindsTo: 'face_refs',
        type: VariableType.imageList,
        label: 'Training photos',
        help: 'One face, varied angles, consistent lighting, no sunglasses. Recent photos train better.',
        example: 'selfie_01.jpg … selfie_24.jpg',
        constraints: VariableConstraints(minItems: 20, maxItems: 80),
      ),
      PromptVariable(
        key: 'scene',
        bindsTo: 'scene',
        type: VariableType.text,
        label: 'Outfit and setting',
        help: 'What the character is wearing and where they are.',
        example: 'cream linen blazer, bright plant-filled studio',
        defaultValue: 'cream linen blazer, bright plant-filled studio',
      ),
      PromptVariable(
        key: 'aspect',
        bindsTo: 'aspect',
        type: VariableType.enumChoice,
        label: 'Aspect ratio',
        help: 'Frame shape for the generated set.',
        example: '3:4',
        defaultValue: '3:4',
        options: ['1:1', '3:4', '9:16'],
      ),
      PromptVariable(
        key: 'variations',
        type: VariableType.number,
        label: 'Variations',
        help: 'How many portraits to generate per run.',
        example: '4',
        defaultValue: '4',
        required: false,
        constraints: VariableConstraints(min: 1, max: 8),
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Train the Soul ID',
        toolId: 'higgsfield',
        modelLabel: 'Soul ID',
        actionType: StepActionType.upload,
        where: 'Higgsfield → Characters → Create Soul ID',
        inputs: [
          StepInput.variable('reference_photos', label: 'Training photos'),
        ],
        produces: StepOutput(
          id: 'soul_id',
          label: 'Trained character, selectable in the Character tab',
          type: 'tool_artifact',
        ),
        expectedOutput: 'A named identity you can select in later generations.',
        guardrails: [
          'Fewer than ~20 photos, or photos all from one angle, produces an identity that drifts between generations.',
        ],
        estMinutes: 8,
      ),
      PromptStep(
        order: 2,
        title: 'Generate the portrait set',
        toolId: 'higgsfield',
        modelLabel: 'Soul 2.0',
        actionType: StepActionType.prompt,
        prompt: '{{character_name}}, {{scene}}, studio lighting, 50mm portrait, shot on Sony A7IV',
        settings: {
          'character': '{{character_name}}',
          'aspect_ratio': '{{aspect}}',
          'variations': '{{variations}}',
        },
        inputs: [StepInput.fromStep('soul_id', label: 'Trained Soul ID')],
        produces: StepOutput(
          id: 'portrait_set',
          label: 'Portrait variations',
          type: 'image[]',
        ),
        expectedOutput:
            'On-model portraits that hold the same face across runs.',
        guardrails: [
          'Keep the prompt under ~75 words. Longer prompts dilute the identity lock and the face starts drifting.',
        ],
        estMinutes: 3,
      ),
      PromptStep(
        order: 3,
        title: 'Upscale and export',
        toolId: 'higgsfield',
        actionType: StepActionType.export,
        where: 'Select a result → Upscale → 2x → PNG',
        inputs: [StepInput.fromStep('portrait_set', label: 'Chosen portrait')],
        produces: StepOutput(
          id: 'final_png',
          label: 'Production-ready PNG',
          type: 'image',
        ),
        expectedOutput:
            'A 2x upscaled PNG suitable for print or a store listing.',
        estMinutes: 2,
      ),
    ],
    bundledAssets: const [
      GalleryAsset(
        label: 'Author reference sheet',
        role: AssetRole.inputExample,
        kind: AssetKind.before,
      ),
    ],
    gallery: const [
      GalleryAsset(label: '3 raw reference selfies', kind: AssetKind.before),
      GalleryAsset(label: 'Studio portrait, set A', variableSet: 'set_a'),
      GalleryAsset(label: 'Gym setting, set B', variableSet: 'set_b'),
    ],
    freshness: Freshness(
      verifiedOn: DateTime(2026, 9, 2),
      verifiedBy: 'library',
      verifiedAgainstModelLabel: 'Soul 2.0',
      signals: FreshnessSignals(works: 128, broken: 3),
    ),
    stats: const VariantStats(copies: 412, forks: 37),
  ),

  // ---------------------------------------------------------------------
  // goal_consistent_avatar — variant B: OpenArt, from an AI-made character
  // Same goal, same binds_to keys, entirely different native syntax.
  // ---------------------------------------------------------------------
  PromptVariant(
    id: 'var_oa_char2',
    goalId: 'goal_consistent_avatar',
    toolId: 'openart',
    modelLabel: 'Character 2.0',
    inputMethodId: 'from_scratch',
    title: 'SAMPLE: Consistent avatar with OpenArt Character 2.0',
    summary:
        'The same reusable-identity goal, starting from an AI-generated '
        'character instead of real photos.',
    variables: const [
      PromptVariable(
        key: 'trigger_word',
        bindsTo: 'identity_name',
        type: VariableType.text,
        label: 'Trigger word',
        help: 'Must lead every prompt, otherwise the trained character is not applied.',
        example: 'Mira',
        defaultValue: 'Mira',
      ),
      PromptVariable(
        key: 'reference_image',
        bindsTo: 'face_refs',
        type: VariableType.image,
        label: 'Reference image',
        help: 'Character 2.0 needs one clear reference, not a training set.',
        example: 'character_ref.png',
        constraints: VariableConstraints(minItems: 1, maxItems: 1),
      ),
      PromptVariable(
        key: 'scene',
        bindsTo: 'scene',
        type: VariableType.text,
        label: 'Outfit and setting',
        help: 'Describe setting, mood and wardrobe after the trigger word.',
        example: 'cream linen blazer, bright plant-filled studio',
        defaultValue: 'cream linen blazer, bright plant-filled studio',
      ),
      PromptVariable(
        key: 'aspect',
        bindsTo: 'aspect',
        type: VariableType.enumChoice,
        label: 'Aspect ratio',
        help: 'Frame shape.',
        example: '3:4',
        defaultValue: '3:4',
        options: ['1:1', '3:4', '9:16'],
      ),
      PromptVariable(
        key: 'seed',
        type: VariableType.number,
        label: 'Seed lock',
        help: 'Reuse a seed to reproduce a result exactly. Tool-specific — no equivalent in other tools.',
        example: '184402',
        required: false,
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Create the character',
        toolId: 'openart',
        modelLabel: 'Character 2.0',
        actionType: StepActionType.upload,
        where: 'OpenArt → Characters → Create',
        inputs: [
          StepInput.variable('reference_image', label: 'Reference image'),
        ],
        produces: StepOutput(
          id: 'character_model',
          label: 'Saved character',
          type: 'tool_artifact',
        ),
        expectedOutput: 'A reusable character selectable in the prompt bar.',
        guardrails: [
          'A reference with heavy shadow or a cropped chin produces a character that changes face shape between scenes.',
        ],
        estMinutes: 4,
      ),
      PromptStep(
        order: 2,
        title: 'Generate the scene',
        toolId: 'openart',
        modelLabel: 'Character 2.0',
        actionType: StepActionType.prompt,
        prompt: '{{trigger_word}}, {{scene}}, cinematic lighting, 4k',
        negativePrompt: 'deformed, extra limbs, blurry, watermark, text',
        settings: {
          'aspect_ratio': '{{aspect}}',
          'seed': '{{seed}}',
          'character': '{{trigger_word}}',
        },
        inputs: [
          StepInput.fromStep('character_model', label: 'Saved character'),
        ],
        produces: StepOutput(
          id: 'scene_image',
          label: 'Scene image',
          type: 'image',
        ),
        expectedOutput:
            'An on-model image of the character in the requested scene.',
        guardrails: [
          'Dropping the trigger word from the front of the prompt silently generates a different person.',
        ],
        estMinutes: 2,
      ),
    ],
    gallery: const [
      GalleryAsset(
        label: 'AI-generated character sheet',
        kind: AssetKind.before,
      ),
      GalleryAsset(label: 'Studio scene, set A', variableSet: 'set_a'),
      GalleryAsset(label: 'Outdoor scene, set B', variableSet: 'set_b'),
    ],
    // Deliberately older, to show the decay rule flipping a prompt to
    // "aging" without anyone touching it.
    freshness: Freshness(
      verifiedOn: DateTime(2026, 7, 10),
      verifiedAgainstModelLabel: 'Character 2.0',
      signals: FreshnessSignals(works: 76, broken: 4),
    ),
    stats: const VariantStats(copies: 188, forks: 12),
  ),

  // ---------------------------------------------------------------------
  PromptVariant(
    id: 'var_cd_motion_page',
    goalId: 'goal_animated_landing',
    toolId: 'claude_design',
    modelLabel: 'Claude Opus 5 (Design)',
    inputMethodId: 'from_scratch',
    title: 'SAMPLE: Animated one-page site with Claude Design',
    summary:
        'A structured brief that produces a self-contained responsive page '
        'with motion that serves the content.',
    variables: const [
      PromptVariable(
        key: 'brand_name',
        bindsTo: 'brand_name',
        type: VariableType.text,
        label: 'Brand name',
        help: 'The brand the page is for.',
        example: 'Northwind Studio',
        defaultValue: 'Northwind Studio',
      ),
      PromptVariable(
        key: 'headline',
        bindsTo: 'headline',
        type: VariableType.text,
        label: 'Hero headline',
        help: 'The one line the page leads with.',
        example: 'Motion that sells itself',
        defaultValue: 'Motion that sells itself',
      ),
      PromptVariable(
        key: 'cta_label',
        type: VariableType.text,
        label: 'Button label',
        help: 'Text on the primary call to action.',
        example: 'Book a demo',
        defaultValue: 'Book a demo',
      ),
      PromptVariable(
        key: 'primary_color',
        bindsTo: 'primary_color',
        type: VariableType.color,
        label: 'Primary colour',
        help: 'Accent used for the CTA and highlights.',
        example: '#6C4DFF',
        defaultValue: '#6C4DFF',
      ),
      PromptVariable(
        key: 'background_color',
        type: VariableType.color,
        label: 'Background colour',
        help: 'Base page ground.',
        example: '#0B0B10',
        defaultValue: '#0B0B10',
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Generate the animated page',
        toolId: 'claude_design',
        modelLabel: 'Claude Opus 5 (Design)',
        actionType: StepActionType.prompt,
        prompt:
            'Design a one-page animated marketing site for {{brand_name}}.\n\n'
            'Sections, in order:\n'
            '1. Hero — slow drifting gradient ground, headline "{{headline}}" fades and '
            'slides up on load, CTA "{{cta_label}}" with a hover scale and glow.\n'
            '2. Feature strip — three cards revealing on scroll with a staggered fade.\n'
            '3. Testimonial marquee — auto-scrolling quote cards, pause on hover.\n'
            '4. Footer — static.\n\n'
            'Motion rules:\n'
            '- CSS transitions and keyframes only, no animation library.\n'
            '- Honour prefers-reduced-motion.\n'
            '- Nothing animates in from opacity 0 on load above the fold.\n\n'
            'Palette: primary {{primary_color}}, ground {{background_color}}.\n'
            'Output: one responsive HTML file with inline style and script.',
        inputs: [
          StepInput.variable('brand_name'),
          StepInput.variable('headline'),
          StepInput.variable('primary_color'),
        ],
        produces: StepOutput(
          id: 'page_html',
          label: 'Single-file HTML page',
          type: 'text',
        ),
        expectedOutput:
            'A responsive single-file page with scroll and hover motion.',
        guardrails: [
          'Asking for more than four sections in one pass produces generic filler copy in the lower sections — generate those separately.',
        ],
        estMinutes: 5,
      ),
    ],
    gallery: const [
      GalleryAsset(label: 'Brief only', kind: AssetKind.before),
      GalleryAsset(label: 'Rendered page, set A', variableSet: 'set_a'),
      GalleryAsset(label: 'Rendered page, set B', variableSet: 'set_b'),
    ],
    freshness: Freshness(
      verifiedOn: DateTime(2026, 9, 12),
      verifiedAgainstModelLabel: 'Claude Opus 5 (Design)',
      signals: FreshnessSignals(works: 54, broken: 1),
    ),
    stats: const VariantStats(copies: 143, forks: 21),
  ),

  // ---------------------------------------------------------------------
  PromptVariant(
    id: 'var_claude_agency_copy',
    goalId: 'goal_agency_landing_copy',
    toolId: 'claude',
    modelLabel: 'Claude Sonnet 5',
    inputMethodId: 'from_scratch',
    title: 'SAMPLE: Real estate landing page copy with Claude',
    summary: 'Outline, final section copy and SEO metadata in one pass.',
    variables: const [
      PromptVariable(
        key: 'agency_name',
        bindsTo: 'brand_name',
        type: VariableType.text,
        label: 'Agency name',
        help: 'The agency the page is for.',
        example: 'Harborline Realty',
        defaultValue: 'Harborline Realty',
      ),
      PromptVariable(
        key: 'service_area',
        bindsTo: 'region',
        type: VariableType.text,
        label: 'Service area',
        help: 'City or region served.',
        example: 'coastal Maine',
        defaultValue: 'coastal Maine',
      ),
      PromptVariable(
        key: 'tone',
        type: VariableType.enumChoice,
        label: 'Tone',
        help: 'Voice for the copy.',
        example: 'warm and confident',
        defaultValue: 'warm and confident',
        options: [
          'warm and confident',
          'luxury and polished',
          'friendly and local',
        ],
      ),
      PromptVariable(
        key: 'primary_keyword',
        type: VariableType.text,
        label: 'Target keyword',
        help: 'Main search term for the meta title and H1.',
        example: 'coastal Maine real estate agent',
        defaultValue: 'coastal Maine real estate agent',
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Write the outline and copy',
        toolId: 'claude',
        modelLabel: 'Claude Sonnet 5',
        actionType: StepActionType.prompt,
        prompt:
            'Write the copy and section structure for a real estate agency landing '
            'page for "{{agency_name}}", serving {{service_area}}.\n\n'
            'Return:\n'
            '1. A section-by-section outline (Hero, Value props, Listings preview, '
            'Agent bios, Testimonials, Contact CTA)\n'
            '2. Final copy for each section in a {{tone}} tone\n'
            '3. H1/H2 hierarchy and a meta title and description targeting '
            '"{{primary_keyword}}"\n\n'
            'Short sentences. No more than 400 words across all sections.',
        produces: StepOutput(
          id: 'page_copy',
          label: 'Outline and copy',
          type: 'text',
        ),
        expectedOutput: 'An outline, final copy per section, and SEO metadata.',
        guardrails: [
          'Without the word limit it returns roughly twice the copy a landing page can carry, and the value props turn generic.',
        ],
        estMinutes: 3,
      ),
    ],
    gallery: const [
      GalleryAsset(label: 'Brief only', kind: AssetKind.before),
      GalleryAsset(label: 'Outline and copy, set A', variableSet: 'set_a'),
      GalleryAsset(
        label: 'Fitness studio variant, set B',
        variableSet: 'set_b',
      ),
    ],
    freshness: Freshness(
      verifiedOn: DateTime(2026, 8, 21),
      verifiedAgainstModelLabel: 'Claude Sonnet 5',
      signals: FreshnessSignals(works: 63, broken: 2),
    ),
    stats: const VariantStats(copies: 97, forks: 8),
  ),

  // ---------------------------------------------------------------------
  PromptVariant(
    id: 'var_heygen_ugc',
    goalId: 'goal_ugc_social_video',
    toolId: 'heygen',
    modelLabel: 'Avatar IV',
    inputMethodId: 'own_photo',
    title: 'SAMPLE: UGC-style talking avatar video with HeyGen',
    summary:
        'Claude writes the script, HeyGen performs it as a captioned vertical '
        'clip. Two tools, one recipe.',
    variables: const [
      PromptVariable(
        key: 'product_name',
        bindsTo: 'product_name',
        type: VariableType.text,
        label: 'Product',
        help: 'What the clip is promoting.',
        example: 'GlowDrop Serum',
        defaultValue: 'GlowDrop Serum',
      ),
      PromptVariable(
        key: 'platform',
        type: VariableType.enumChoice,
        label: 'Platform',
        help: 'Where the clip will be posted.',
        example: 'TikTok',
        defaultValue: 'TikTok',
        options: ['TikTok', 'Instagram Reels', 'YouTube Shorts'],
      ),
      PromptVariable(
        key: 'cta',
        bindsTo: 'cta',
        type: VariableType.text,
        label: 'Call to action',
        help: 'The spoken closing line.',
        example: 'link in bio, code GLOW10',
        defaultValue: 'link in bio, code GLOW10',
      ),
      PromptVariable(
        key: 'avatar_photo',
        bindsTo: 'face_refs',
        type: VariableType.image,
        label: 'Presenter photo',
        help: 'A clear, front-facing photo to animate.',
        example: 'creator.jpg',
        constraints: VariableConstraints(minItems: 1, maxItems: 1),
      ),
      PromptVariable(
        key: 'voice_style',
        type: VariableType.enumChoice,
        label: 'Voice style',
        help: 'Delivery of the generated voiceover.',
        example: 'upbeat, casual',
        defaultValue: 'upbeat, casual',
        options: ['upbeat, casual', 'calm, confident', 'energetic, fast-paced'],
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Write the 30-second script',
        toolId: 'claude',
        modelLabel: 'Claude Sonnet 5',
        actionType: StepActionType.prompt,
        prompt:
            'Write a 30-second first-person UGC-style script promoting '
            '{{product_name}} for {{platform}}.\n'
            'Hook in the first 3 seconds. Close on the spoken line: "{{cta}}".\n'
            'Return only the spoken lines, broken into timed lines of at most 8 words.',
        produces: StepOutput(
          id: 'script',
          label: 'Timed spoken script',
          type: 'text',
        ),
        expectedOutput: 'A line-by-line script with timings.',
        guardrails: [
          'Without the 8-word line cap the avatar delivery runs long and the captions overflow the safe area.',
        ],
        estMinutes: 2,
      ),
      PromptStep(
        order: 2,
        title: 'Generate the talking avatar video',
        toolId: 'heygen',
        modelLabel: 'Avatar IV',
        actionType: StepActionType.setting,
        where: 'HeyGen → Create video → Photo avatar',
        settings: {
          'avatar': '{{avatar_photo}}',
          'voice': '{{voice_style}}',
          'aspect_ratio': '9:16',
          'captions': 'auto, burned-in',
        },
        inputs: [
          StepInput.fromStep('script', label: 'Script from step 1'),
          StepInput.variable('avatar_photo', label: 'Presenter photo'),
        ],
        produces: StepOutput(
          id: 'clip',
          label: 'Vertical captioned clip',
          type: 'video',
        ),
        expectedOutput: 'A 9:16 captioned talking-avatar clip.',
        guardrails: [
          'Photos where the mouth is partly covered produce visible warping around the jaw when the avatar speaks.',
        ],
        estMinutes: 6,
      ),
    ],
    gallery: const [
      GalleryAsset(label: 'Front-facing creator photo', kind: AssetKind.before),
      GalleryAsset(label: 'Captioned clip, set A', variableSet: 'set_a'),
      GalleryAsset(label: 'Supplement brand, set B', variableSet: 'set_b'),
    ],
    freshness: Freshness(
      verifiedOn: DateTime(2026, 9, 5),
      verifiedAgainstModelLabel: 'Avatar IV',
      signals: FreshnessSignals(works: 91, broken: 5),
    ),
    stats: const VariantStats(copies: 220, forks: 30),
  ),

  // ---------------------------------------------------------------------
  // Old enough to have decayed past the review threshold.
  PromptVariant(
    id: 'var_kling_turntable',
    goalId: 'goal_product_turntable',
    toolId: 'kling',
    modelLabel: 'Kling 2.1',
    inputMethodId: 'own_photo',
    title: 'SAMPLE: Product photo to turntable video with Kling',
    summary: 'Animates one studio still into a seamless looping product clip.',
    variables: const [
      PromptVariable(
        key: 'product_photo',
        bindsTo: 'product_shot',
        type: VariableType.image,
        label: 'Product photo',
        help: 'A clean, evenly lit studio shot on a plain ground.',
        example: 'kettle_hero.jpg',
        constraints: VariableConstraints(minItems: 1, maxItems: 1),
      ),
      PromptVariable(
        key: 'product_name',
        bindsTo: 'product_name',
        type: VariableType.text,
        label: 'Product',
        help: 'Named in the motion description.',
        example: 'ceramic pour-over kettle',
        defaultValue: 'ceramic pour-over kettle',
      ),
      PromptVariable(
        key: 'background_style',
        type: VariableType.text,
        label: 'Background',
        help: 'Backdrop behind the product.',
        example: 'soft gradient grey',
        defaultValue: 'soft gradient grey',
      ),
      PromptVariable(
        key: 'duration',
        type: VariableType.enumChoice,
        label: 'Duration',
        help: 'Clip length.',
        example: '5s',
        defaultValue: '5s',
        options: ['5s', '8s', '10s'],
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Animate the still',
        toolId: 'kling',
        suggestedToolIds: ['runway'],
        modelLabel: 'Kling 2.1',
        actionType: StepActionType.prompt,
        prompt:
            '{{product_name}} rotating slowly on a reflective podium, studio softbox '
            'lighting, subtle dust particles, {{background_style}} background, camera '
            'holds steady',
        negativePrompt: 'warping, melting edges, text, watermark',
        settings: {
          'mode': 'image-to-video',
          'image': '{{product_photo}}',
          'motion_strength': '4',
          'duration': '{{duration}}',
          'loop': 'seamless',
        },
        inputs: [StepInput.variable('product_photo', label: 'Product photo')],
        produces: StepOutput(
          id: 'loop_clip',
          label: 'Looping product clip',
          type: 'video',
        ),
        expectedOutput: 'A seamless looping turntable clip.',
        guardrails: [
          'Motion strength above ~5 warps product edges and text on packaging becomes unreadable.',
          'Products shot on a busy background pull scenery into the rotation.',
        ],
        estMinutes: 4,
      ),
    ],
    gallery: const [
      GalleryAsset(label: 'Static studio still', kind: AssetKind.before),
      GalleryAsset(label: 'Turntable loop, set A', variableSet: 'set_a'),
      GalleryAsset(label: 'Cosmetics bottle, set B', variableSet: 'set_b'),
    ],
    freshness: Freshness(
      verifiedOn: DateTime(2026, 6, 5),
      verifiedAgainstModelLabel: 'Kling 2',
      signals: FreshnessSignals(works: 47, broken: 6),
    ),
    stats: const VariantStats(copies: 76, forks: 5),
  ),

  // ---------------------------------------------------------------------
  // Tool-agnostic: no toolId at the variant level, steps suggest tools.
  PromptVariant(
    id: 'var_multi_brand_kit',
    goalId: 'goal_starter_brand_kit',
    toolId: null,
    modelLabel: '',
    inputMethodId: 'from_template',
    title: 'SAMPLE: Universal starter brand kit recipe',
    summary:
        'Four steps from a name to a usable kit. No tool preselected — each '
        'step suggests options so it works with whatever you have access to.',
    variables: const [
      PromptVariable(
        key: 'brand_name',
        bindsTo: 'brand_name',
        type: VariableType.text,
        label: 'Brand name',
        help: 'The brand this kit is for.',
        example: 'Lumen & Co',
        defaultValue: 'Lumen & Co',
      ),
      PromptVariable(
        key: 'industry',
        type: VariableType.text,
        label: 'Industry',
        help: 'What the brand does.',
        example: 'sustainable home goods',
        defaultValue: 'sustainable home goods',
      ),
      PromptVariable(
        key: 'style_keywords',
        bindsTo: 'style_keywords',
        type: VariableType.text,
        label: 'Style keywords',
        help: 'Three or four adjectives for the look.',
        example: 'warm, minimal, handcrafted',
        defaultValue: 'warm, minimal, handcrafted',
      ),
      PromptVariable(
        key: 'primary_color',
        bindsTo: 'primary_color',
        type: VariableType.color,
        label: 'Primary colour',
        help: 'The brand\'s main colour.',
        example: '#C97C3D',
        defaultValue: '#C97C3D',
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Logo concept exploration',
        suggestedToolIds: ['midjourney', 'openart'],
        actionType: StepActionType.prompt,
        prompt:
            '{{brand_name}}, minimalist logo mark, {{industry}}, {{style_keywords}}, '
            'vector style, flat, white background, no text --ar 1:1 --v 7 --style raw',
        produces: StepOutput(
          id: 'logo_marks',
          label: 'Logo concepts',
          type: 'image[]',
        ),
        expectedOutput: 'Four to six marks to shortlist from.',
        guardrails: [
          'Leaving "no text" out returns marks with unreadable pseudo-lettering baked in.',
        ],
        estMinutes: 5,
      ),
      PromptStep(
        order: 2,
        title: 'Voice and palette guide',
        toolId: 'claude',
        modelLabel: 'Claude Sonnet 5',
        actionType: StepActionType.prompt,
        prompt:
            'Define a brand style guide for "{{brand_name}}", a {{industry}} brand: a '
            'three-word brand voice, primary colour {{primary_color}} with two '
            'supporting colours as hex, a heading and body font pairing, and five '
            'dos and don\'ts for tone.',
        produces: StepOutput(
          id: 'style_guide',
          label: 'Written style guide',
          type: 'text',
        ),
        expectedOutput: 'Voice, palette and type direction in one page.',
        estMinutes: 3,
      ),
      PromptStep(
        order: 3,
        title: 'Social template set',
        suggestedToolIds: ['openart', 'claude_design'],
        actionType: StepActionType.prompt,
        prompt:
            'Create a three-tile Instagram template set for {{brand_name}} using '
            '{{primary_color}} and the supporting palette, logo lockup top-left, '
            'consistent grid, {{style_keywords}} aesthetic.',
        inputs: [
          StepInput.fromStep('logo_marks', label: 'Chosen logo'),
          StepInput.fromStep('style_guide', label: 'Palette and type'),
        ],
        produces: StepOutput(
          id: 'social_set',
          label: 'Template tiles',
          type: 'image[]',
        ),
        expectedOutput: 'Three reusable post templates.',
        estMinutes: 6,
      ),
      PromptStep(
        order: 4,
        title: 'One-page guideline sheet',
        toolId: 'claude_design',
        modelLabel: 'Claude Opus 5 (Design)',
        actionType: StepActionType.prompt,
        prompt:
            'Design a single-page HTML brand guideline for {{brand_name}}: logo '
            'clearspace, colour swatches with hex codes, a type scale, and three '
            'applications (business card, social post, site header).',
        inputs: [
          StepInput.fromStep('logo_marks', label: 'Chosen logo'),
          StepInput.fromStep('style_guide', label: 'Palette and type'),
        ],
        produces: StepOutput(
          id: 'guideline_sheet',
          label: 'Guideline page',
          type: 'text',
        ),
        expectedOutput: 'A shareable one-page guideline.',
        guardrails: [
          'Without the explicit application list it produces swatches only, which is not enough for a client handoff.',
        ],
        estMinutes: 5,
      ),
    ],
    gallery: const [
      GalleryAsset(label: 'Brand name and keywords', kind: AssetKind.before),
      GalleryAsset(label: 'Assembled kit, set A', variableSet: 'set_a'),
      GalleryAsset(label: 'Coffee brand, set B', variableSet: 'set_b'),
    ],
    freshness: Freshness(
      verifiedOn: DateTime(2026, 9, 10),
      signals: FreshnessSignals(works: 39, broken: 1),
    ),
    stats: const VariantStats(copies: 61, forks: 19),
  ),

  // ---------------------------------------------------------------------
  // Enough broken reports to flip status to broken — the Midjourney v7
  // --cref/--oref change is exactly the failure this system exists to catch.
  PromptVariant(
    id: 'var_mj_realestate_kit',
    goalId: 'goal_realestate_brand_kit',
    toolId: 'midjourney',
    modelLabel: 'v7',
    inputMethodId: 'from_scratch',
    title: 'SAMPLE: Real estate brand kit with Midjourney and Claude',
    summary: 'A logo mark, then a written guideline tying the kit together.',
    variables: const [
      PromptVariable(
        key: 'agency_name',
        bindsTo: 'brand_name',
        type: VariableType.text,
        label: 'Agency name',
        help: 'The agency this kit is for.',
        example: 'Harborline Realty',
        defaultValue: 'Harborline Realty',
      ),
      PromptVariable(
        key: 'style_keywords',
        bindsTo: 'style_keywords',
        type: VariableType.text,
        label: 'Style keywords',
        help: 'Adjectives for the mark.',
        example: 'trustworthy, modern, coastal',
        defaultValue: 'trustworthy, modern, coastal',
      ),
      PromptVariable(
        key: 'primary_color',
        bindsTo: 'primary_color',
        type: VariableType.color,
        label: 'Primary colour',
        help: 'Main brand colour.',
        example: '#0B3D5C',
        defaultValue: '#0B3D5C',
      ),
      PromptVariable(
        key: 'secondary_color',
        type: VariableType.color,
        label: 'Accent colour',
        help: 'Supporting colour.',
        example: '#D4AF37',
        defaultValue: '#D4AF37',
      ),
    ],
    steps: const [
      PromptStep(
        order: 1,
        title: 'Logo mark',
        toolId: 'midjourney',
        modelLabel: 'v7',
        actionType: StepActionType.prompt,
        prompt:
            '{{agency_name}} real estate logo, house and skyline monogram, '
            '{{style_keywords}}, flat vector, navy and gold, white background '
            '--ar 1:1 --v 7 --style raw --stylize 100',
        produces: StepOutput(
          id: 'logo_mark',
          label: 'Logo concepts',
          type: 'image[]',
        ),
        expectedOutput: 'Four logo concepts.',
        guardrails: [
          'On v7 the character-reference flag is --oref, not v6\'s --cref. Prompts copied from older guides fail silently.',
        ],
        estMinutes: 4,
      ),
      PromptStep(
        order: 2,
        title: 'Brand guideline summary',
        toolId: 'claude',
        modelLabel: 'Claude Sonnet 5',
        actionType: StepActionType.prompt,
        prompt:
            'Write a one-page brand guideline for {{agency_name}}: colour codes '
            '({{primary_color}}, {{secondary_color}}), a font pairing, logo usage '
            'rules, and three sample taglines.',
        inputs: [StepInput.fromStep('logo_mark', label: 'Chosen mark')],
        produces: StepOutput(
          id: 'guideline',
          label: 'Written guideline',
          type: 'text',
        ),
        expectedOutput: 'A one-page guideline with taglines.',
        estMinutes: 3,
      ),
    ],
    gallery: const [
      GalleryAsset(label: 'Agency name only', kind: AssetKind.before),
      GalleryAsset(label: 'Mark and guideline, set A', variableSet: 'set_a'),
      GalleryAsset(label: 'Urban agency, set B', variableSet: 'set_b'),
    ],
    freshness: Freshness(
      verifiedOn: DateTime(2026, 8, 15),
      verifiedAgainstModelLabel: 'v6.1',
      signals: FreshnessSignals(works: 8, broken: 5),
      history: [
        FreshnessRevision(
          version: 2,
          changedOn: DateTime(2026, 8, 15),
          reason:
              'Midjourney v7 replaced --cref with --oref; step 1 rewritten.',
        ),
      ],
    ),
    stats: const VariantStats(copies: 34, forks: 3),
  ),
];
