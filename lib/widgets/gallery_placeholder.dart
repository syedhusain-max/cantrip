import 'package:flutter/material.dart';

import '../models/gallery_asset.dart';

/// Renders a gallery asset.
///
/// The sample library carries no image files, so this draws a labelled
/// gradient tile derived from the label — the layout is real before the
/// images are, and a missing file never shows as a broken box. When [uri]
/// is set (once assets live in storage) it renders the image instead.
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
          if (asset.uri != null)
            Image.network(asset.uri!, fit: BoxFit.cover)
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [base, tip],
                ),
              ),
            ),
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
