import 'package:flutter/material.dart';

import '../models/gallery_asset.dart';

/// Renders a gallery asset: the image when there is one, a labelled
/// gradient tile when there isn't.
///
/// The fallback is not a placeholder for development — it is the permanent
/// failure mode. A gallery image that 404s, or hasn't been shot yet, shows
/// the same labelled tile as a prompt with no image at all, so the page
/// never degrades into a broken box. The label and variable-set chip sit on
/// top either way, because they are what tell a reader *which* run they are
/// looking at.
class GalleryPlaceholder extends StatelessWidget {
  final GalleryAsset asset;

  const GalleryPlaceholder({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final hue = (asset.label.hashCode % 360).abs().toDouble();
    final base = HSLColor.fromAHSL(
      1,
      hue,
      0.45,
      isDark ? 0.26 : 0.84,
    ).toColor();
    final tip = HSLColor.fromAHSL(
      1,
      (hue + 38) % 360,
      0.45,
      isDark ? 0.17 : 0.92,
    ).toColor();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Tile(base: base, tip: tip),
          if (asset.uri != null)
            // Drawn over the tile rather than instead of it, so a slow or
            // failed load reveals the gradient underneath instead of a gap.
            _AssetImage(asset: asset),
          Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      asset.kind == AssetKind.before
                          ? Icons.photo_outlined
                          : Icons.auto_awesome_outlined,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const Spacer(),
                    if (asset.variableSet != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black38 : Colors.white70,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          asset.variableSet!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                        ),
                      ),
                  ],
                ),
                Text(
                  asset.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Color base;
  final Color tip;

  const _Tile({required this.base, required this.tip});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [base, tip],
      ),
    ),
  );
}

class _AssetImage extends StatelessWidget {
  final GalleryAsset asset;

  const _AssetImage({required this.asset});

  @override
  Widget build(BuildContext context) {
    final uri = asset.uri!;
    const fit = BoxFit.cover;
    // An error builder that returns nothing is the point: the gradient tile
    // is already painted underneath.
    Widget onError(BuildContext _, Object _, StackTrace? _) =>
        const SizedBox.shrink();

    if (asset.isBundled) {
      return Image.asset(uri, fit: fit, errorBuilder: onError);
    }
    return Image.network(
      uri,
      fit: fit,
      errorBuilder: onError,
      // Fades in rather than popping, and leaves the tile visible while
      // the bytes are still arriving.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 220),
          child: child,
        );
      },
    );
  }
}
