import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cantrip/models/gallery_asset.dart';
import 'package:cantrip/widgets/gallery_placeholder.dart';

Widget host(GalleryAsset asset) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 300,
      height: 200,
      child: GalleryPlaceholder(asset: asset),
    ),
  ),
);

void main() {
  group('gallery', () {
    test('the loader is chosen by the uri, not by a separate flag', () {
      const bundled = GalleryAsset(
        label: 'Studio portrait',
        uri: 'assets/gallery/v/after-set_a.webp',
      );
      const hosted = GalleryAsset(
        label: 'Studio portrait',
        uri: 'https://cdn.example.com/after.webp',
      );
      const missing = GalleryAsset(label: 'Studio portrait');

      expect(bundled.isBundled, isTrue);
      expect(hosted.isBundled, isFalse);
      expect(missing.isBundled, isFalse);
    });

    testWidgets('an image with no file still shows its label and set', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const GalleryAsset(label: 'Studio portrait', variableSet: 'set_b'),
        ),
      );
      await tester.pump();

      // The label and the set chip are what tell a reader which run they
      // are looking at, so they must survive a missing image.
      expect(find.text('Studio portrait'), findsOneWidget);
      expect(find.text('set_b'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a bundled path renders an asset image over the tile', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const GalleryAsset(
            label: 'Studio portrait',
            uri: 'assets/gallery/var_x/after-set_a.webp',
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      // The label stays legible on top of the image.
      expect(find.text('Studio portrait'), findsOneWidget);
    });

    testWidgets('an https uri renders a network image', (tester) async {
      await tester.pumpWidget(
        host(
          const GalleryAsset(
            label: 'Studio portrait',
            uri: 'https://cdn.example.com/after-set_a.webp',
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<NetworkImage>(),
      );
    });
  });
}
