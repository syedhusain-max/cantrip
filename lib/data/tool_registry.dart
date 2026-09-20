import '../models/taxonomy.dart';

/// Every AI tool the library knows about.
///
/// This is the file the architecture requirement is really about: adding a
/// brand-new tool means adding one entry here plus its variants in the
/// library. No screen, filter, badge or validator needs to change.
///
/// [ToolDef.sendCapability] is deliberately conservative. Android's share
/// sheet only reaches apps that declare a matching ACTION_SEND intent
/// filter, and most of these tools are web-first with nothing installed to
/// receive one. Every entry stays `clipboardOnly` until the alternative has
/// been tested on a real device — a button that looks like it will open a
/// tool and doesn't is worse than no button.
const List<ToolDef> toolRegistry = [
  ToolDef(
    id: 'higgsfield',
    name: 'Higgsfield',
    accentValue: 0xFF6C4DFF,
    platforms: ['web'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Soul 2.0', 'Soul ID', 'Soul'],
    syntaxFlags: [
      'soul_id',
      'character',
      'aspect_ratio',
      'variations',
      'scale',
    ],
    docsUrl: 'https://higgsfield.ai',
  ),
  ToolDef(
    id: 'openart',
    name: 'OpenArt',
    accentValue: 0xFF00A896,
    platforms: ['web'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Character 2.0', 'Consistent Character'],
    syntaxFlags: [
      'negative_prompt',
      'aspect_ratio',
      'seed',
      'character',
      'model',
    ],
    docsUrl: 'https://openart.ai',
  ),
  ToolDef(
    id: 'midjourney',
    name: 'Midjourney',
    accentValue: 0xFF3A3A45,
    platforms: ['web', 'discord'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['v7', 'v6.1', 'v6'],
    // v7 replaced v6's --cref with --oref. Keeping both here would let a
    // stale prompt pass the validator, so the allowlist tracks the label
    // the variant declares.
    syntaxFlags: [
      '--ar',
      '--v',
      '--style',
      '--stylize',
      '--s',
      '--sref',
      '--sw',
      '--oref',
      '--ow',
      '--chaos',
      '--q',
      '--no',
    ],
    docsUrl: 'https://docs.midjourney.com',
  ),
  ToolDef(
    id: 'runway',
    name: 'Runway',
    accentValue: 0xFF0F62FE,
    platforms: ['web'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Gen-4', 'Gen-3 Alpha'],
    syntaxFlags: ['motion', 'duration', 'seed', 'camera'],
    docsUrl: 'https://runwayml.com',
  ),
  ToolDef(
    id: 'claude',
    name: 'Claude',
    accentValue: 0xFFCC785C,
    platforms: ['web', 'android', 'ios', 'desktop'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Claude Sonnet 5', 'Claude Opus 5'],
    syntaxFlags: [],
    docsUrl: 'https://claude.ai',
  ),
  ToolDef(
    id: 'claude_design',
    name: 'Claude Design',
    accentValue: 0xFFB86B4B,
    platforms: ['web'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Claude Opus 5 (Design)'],
    syntaxFlags: [],
    docsUrl: 'https://claude.ai',
  ),
  ToolDef(
    id: 'heygen',
    name: 'HeyGen',
    accentValue: 0xFF12A594,
    platforms: ['web'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Avatar IV', 'Avatar III'],
    syntaxFlags: [
      'avatar',
      'voice',
      'script',
      'background',
      'aspect_ratio',
      'captions',
    ],
    docsUrl: 'https://heygen.com',
  ),
  ToolDef(
    id: 'kling',
    name: 'Kling',
    accentValue: 0xFFE8555D,
    platforms: ['web'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Kling 2.1', 'Kling 2'],
    syntaxFlags: [
      'mode',
      'image',
      'motion_strength',
      'duration',
      'loop',
      'negative_prompt',
    ],
    docsUrl: 'https://klingai.com',
  ),

  // --- Document and presentation tools -------------------------------
  // The eight tools above are image and video generators; none of them
  // produce a slide deck, a dashboard mockup or a paginated PDF. These
  // three cover the deck / dashboard / document / resume goals.
  ToolDef(
    id: 'gamma',
    name: 'Gamma',
    accentValue: 0xFF7C5CFF,
    platforms: ['web'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Gamma 3', 'Gamma 2'],
    syntaxFlags: [
      'format',
      'num_cards',
      'theme',
      'tone',
      'audience',
      'text_amount',
      'image_source',
    ],
    docsUrl: 'https://gamma.app',
  ),
  ToolDef(
    id: 'canva',
    name: 'Canva',
    accentValue: 0xFF00B8C4,
    platforms: ['web', 'android', 'ios'],
    // Canva ships an Android app, so a share-sheet path may exist — but it
    // stays clipboardOnly until it is tested on a real device.
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Magic Design', 'Magic Studio'],
    syntaxFlags: ['style', 'dimensions', 'brand_kit', 'page_count'],
    docsUrl: 'https://canva.com',
  ),
  ToolDef(
    id: 'figma',
    name: 'Figma',
    accentValue: 0xFFF2662E,
    platforms: ['web', 'desktop'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Figma Make', 'First Draft'],
    syntaxFlags: ['frame_size', 'auto_layout', 'components', 'grid'],
    docsUrl: 'https://figma.com',
  ),
];

final Map<String, ToolDef> _toolsById = {for (final t in toolRegistry) t.id: t};

/// Null-safe lookup. An unknown id (stale data, a tool removed from the
/// registry) returns null rather than throwing, and callers render a
/// neutral badge.
ToolDef? toolById(String? id) => id == null ? null : _toolsById[id];

String toolName(String? id, {String fallback = 'Multi-tool'}) =>
    toolById(id)?.name ?? fallback;
