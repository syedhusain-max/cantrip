/// Whether an asset shows the starting point or the result.
enum AssetKind { before, after }

/// What role a bundled asset played for the author.
enum AssetRole { inputExample, styleReference, outputSample }

/// An image attached to a variant.
///
/// Two senses, deliberately kept in one type with different roles: assets
/// the author bundled (the face or logo they used to produce the gallery)
/// and the gallery proof itself. Files the *user* supplies are not assets —
/// they are image-typed variables.
///
/// [uri] is null throughout the sample library; the UI renders a labelled
/// placeholder tile so the layout is real before the images are.
///
/// When set, it is either a bundled asset path (`assets/gallery/…`) or an
/// `https://` URL, and the widget picks the loader by prefix. Bundled is
/// the default because gallery images are proof, and proof that needs a
/// network round trip isn't there when someone is deciding whether to trust
/// the prompt. Host the long tail remotely once the bundle gets heavy.
class GalleryAsset {
  final String label;
  final AssetKind kind;
  final AssetRole role;
  final String? uri;

  /// True when [uri] points into the app bundle rather than the network.
  bool get isBundled => uri != null && !uri!.startsWith('http');

  /// Which variable set produced this output, so a viewer can tell the
  /// author's original run from the second-niche test run that the publish
  /// gate requires.
  final String? variableSet;

  const GalleryAsset({
    required this.label,
    this.kind = AssetKind.after,
    this.role = AssetRole.outputSample,
    this.uri,
    this.variableSet,
  });
}
