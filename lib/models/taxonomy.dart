import 'package:flutter/material.dart';

/// A single entry in one of the library's classification axes (use case,
/// niche, output type, input method).
///
/// These are data, not enums, so adding "UGC ads" as a use case or
/// "hospitality" as a niche is a registry entry — no code change.
///
/// The icon is held directly rather than looked up by name. An earlier
/// version kept a name→IconData map in this file, which quietly broke the
/// data-only promise: a category with a new icon needed an edit here, in
/// the model layer. Now the registry supplies everything.
class Taxon {
  final String id;
  final String label;
  final IconData icon;

  const Taxon({
    required this.id,
    required this.label,
    this.icon = Icons.label_outline,
  });
}

/// How far the app can go when handing a finished prompt to its target tool.
///
/// Android's share sheet only reaches apps that declare a matching
/// ACTION_SEND intent filter, and most AI creative tools are web-first with
/// nothing installed to receive it. Every tool therefore declares what it
/// actually supports, and the UI renders from this — it never offers a
/// button that would silently fail.
enum SendCapability {
  /// Copy to clipboard, then the user pastes. Always available.
  clipboardOnly,

  /// Verified on a real device to receive ACTION_SEND text/plain.
  androidShare,

  /// Opens a URL scheme or app link that lands somewhere useful.
  deepLink,

  /// The tool exposes an API we can post to.
  api,
}

extension SendCapabilityX on SendCapability {
  String get label => switch (this) {
    SendCapability.clipboardOnly => 'Copy only',
    SendCapability.androidShare => 'Share to app',
    SendCapability.deepLink => 'Open in app',
    SendCapability.api => 'Send via API',
  };

  /// Whether a "send" affordance beyond copy should render at all.
  bool get hasSendAction => this != SendCapability.clipboardOnly;
}

/// An AI tool the library carries prompts for.
///
/// This is the entity the architecture requirement is about: a brand-new
/// tool ships as one entry in the tool registry plus its variants. Nothing
/// in the screens, filters or validator needs to change.
class ToolDef {
  final String id;
  final String name;

  /// Accent colour used for the tool's badge, as 0xAARRGGBB.
  final int accentValue;

  /// Where the tool actually runs. Drives realistic send expectations.
  final List<String> platforms;

  final SendCapability sendCapability;

  /// The model/version labels this tool exposes, newest first. Some tools
  /// expose none — an empty list is legal and means "no version surface".
  final List<String> modelLabels;

  /// Parameters and flags valid for this tool, used by the publish
  /// validator to catch prompts written against a superseded syntax
  /// (e.g. Midjourney's --cref becoming --oref in v7).
  final List<String> syntaxFlags;

  final String? docsUrl;

  const ToolDef({
    required this.id,
    required this.name,
    required this.accentValue,
    this.platforms = const [],
    this.sendCapability = SendCapability.clipboardOnly,
    this.modelLabels = const [],
    this.syntaxFlags = const [],
    this.docsUrl,
  });

  Color get accent => Color(accentValue);
}
