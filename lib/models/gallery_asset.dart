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
class GalleryAsset {
  final String label;
  final AssetKind kind;
  final AssetRole role;
  final String? uri;

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
