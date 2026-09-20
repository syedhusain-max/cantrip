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
    flags: [
      FlagSpec('soul_id'),
      FlagSpec('character'),
      FlagSpec('aspect_ratio'),
      FlagSpec('variations'),
      FlagSpec('scale'),
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
    flags: [
      FlagSpec('negative_prompt'),
      FlagSpec('aspect_ratio'),
      FlagSpec('seed'),
      FlagSpec('character'),
      FlagSpec('model'),
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
    // Verified against Midjourney's own release notes, 2026-09-20:
    // https://updates.midjourney.com/omni-reference-oref/
    //
    // This is the entry PR-3 exists for. `--oref` is real Midjourney syntax
    // and still wrong in a prompt labelled v6, which a flat allowlist can't
    // express — hence the per-model `models:`.
    flags: [
      FlagSpec('--ar', values: 'w:h, e.g. 3:4'),
      FlagSpec('--v', values: '7, 6.1, 6'),
      FlagSpec('--style', values: 'raw'),
      FlagSpec('--stylize', values: '0-1000, default 100'),
      FlagSpec('--s', values: '0-1000, alias of --stylize'),
      FlagSpec('--sref', values: 'image URL or style code'),
      FlagSpec('--sw', values: '0-1000, default 100'),
      FlagSpec(
        '--oref',
        models: ['v7'],
        values: 'URL of an already-hosted image',
        note:
            'Omni-reference, V7 and later only. It replaced v6\'s --cref. '
            'Costs 2x GPU time and is incompatible with Fast, Draft and '
            'Conversational modes and with --q 4.',
      ),
      FlagSpec(
        '--ow',
        models: ['v7'],
        values: '0-1000, default 100',
        note:
            'Omni weight. Midjourney warns against going above roughly 400 '
            'unless --stylize and --exp are also extreme: both compete with '
            'omni-reference for influence, so high values can make results '
            'worse rather than more faithful.',
      ),
      FlagSpec(
        '--cref',
        models: ['v6.1', 'v6'],
        values: 'image URL',
        note: 'Character reference. Superseded by --oref in v7.',
      ),
      FlagSpec('--cw', models: ['v6.1', 'v6'], values: '0-100'),
      FlagSpec('--exp', models: ['v7'], values: '0-100'),
      FlagSpec('--chaos'),
      FlagSpec('--q', values: '0.25, 0.5, 1, 2, 4'),
      FlagSpec('--no'),
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
    flags: [
      FlagSpec('motion'),
      FlagSpec('duration'),
      FlagSpec('seed'),
      FlagSpec('camera'),
    ],
    docsUrl: 'https://runwayml.com',
  ),
  ToolDef(
    id: 'claude',
    name: 'Claude',
    accentValue: 0xFFCC785C,
    platforms: ['web', 'android', 'ios', 'desktop'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Claude Sonnet 5', 'Claude Opus 5'],
    flags: [],
    docsUrl: 'https://claude.ai',
  ),
  ToolDef(
    id: 'claude_design',
    name: 'Claude Design',
    accentValue: 0xFFB86B4B,
    platforms: ['web'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Claude Opus 5 (Design)'],
    flags: [],
    docsUrl: 'https://claude.ai',
  ),
  ToolDef(
    id: 'heygen',
    name: 'HeyGen',
    accentValue: 0xFF12A594,
    platforms: ['web'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Avatar IV', 'Avatar III'],
    flags: [
      FlagSpec('avatar'),
      FlagSpec('voice'),
      FlagSpec('script'),
      FlagSpec('background'),
      FlagSpec('aspect_ratio'),
      FlagSpec('captions'),
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
    flags: [
      FlagSpec('mode'),
      FlagSpec('image'),
      FlagSpec('motion_strength'),
      FlagSpec('duration'),
      FlagSpec('loop'),
      FlagSpec('negative_prompt'),
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
    flags: [
      FlagSpec('format'),
      FlagSpec('num_cards'),
      FlagSpec('theme'),
      FlagSpec('tone'),
      FlagSpec('audience'),
      FlagSpec('text_amount'),
      FlagSpec('image_source'),
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
    flags: [
      FlagSpec('style'),
      FlagSpec('dimensions'),
      FlagSpec('brand_kit'),
      FlagSpec('page_count'),
    ],
    docsUrl: 'https://canva.com',
  ),
  ToolDef(
    id: 'figma',
    name: 'Figma',
    accentValue: 0xFFF2662E,
    platforms: ['web', 'desktop'],
    sendCapability: SendCapability.clipboardOnly,
    modelLabels: ['Figma Make', 'First Draft'],
    flags: [
      FlagSpec('frame_size'),
      FlagSpec('auto_layout'),
      FlagSpec('components'),
      FlagSpec('grid'),
    ],
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
