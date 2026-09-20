# Gallery images

Proof that a prompt produces what it claims. The publish gate
(`test/publish_gate_test.dart`, rule PR-4) requires per variant:

- **1 "before"** — the starting point: the reference photo, the rough input,
  the blank state.
- **2 "after"** — the results, and they must come from **two different
  variable sets**. One result proves the prompt ran; two results from
  different inputs prove it generalises rather than being a lucky seed.

## Naming

```
assets/gallery/<variantId>/before-<setId>.webp
assets/gallery/<variantId>/after-<setId>.webp
```

For example:

```
assets/gallery/var_hgf_soulid/before-set_a.webp
assets/gallery/var_hgf_soulid/after-set_a.webp
assets/gallery/var_hgf_soulid/after-set_b.webp
```

`<setId>` is the `variableSet` on the `GalleryAsset`, and it shows on the
image as a chip, so a reader can tell which run they are looking at. Keep
the ids short and stable — they are shown, not just stored.

## Format and size

**WebP, longest edge 1200px, quality ~80.** These ship inside the app, so
every kilobyte is download size for every user. A 1200px WebP of a portrait
lands around 90–150 KB; the same image as PNG is ten times that for no
visible gain on a phone screen.

```bash
cwebp -q 80 -resize 1200 0 input.png -o after-set_a.webp
```

Flutter fetches bundled assets on demand on web, so these do not delay first
paint — but they do count toward the Android download.

## Bundled or hosted

`GalleryAsset.uri` takes either a path under `assets/` or an `https://` URL,
and the widget picks the loader by prefix. Bundle by default: gallery images
are proof, and proof that needs a network round trip isn't there at the
moment someone is deciding whether to trust the prompt. Move the long tail
to a CDN if the bundle gets heavy.

Either way a missing or failed image is not a broken box — the labelled
gradient tile sits underneath every image and shows through.
