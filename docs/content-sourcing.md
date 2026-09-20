# Where prompts come from

Cantrip's claim is that its prompts are tested and still work. Everything
below follows from that claim being true, because the publish gate makes it
checkable: every prompt needs a verification date, a model label, and a
stated failure boundary, and none of those can be honestly supplied for a
prompt copied from someone else's post.

## Sources we use

**Vendor documentation and release notes** — the authority on syntax,
parameter names, ranges and model versions. This is factual reference
material, and it is what keeps the PR-3 flag allowlist correct.

Recorded in `lib/data/tool_registry.dart` as `FlagSpec`s, with the source
and date in a comment next to the entry. Example, verified 2026-09-20 from
<https://updates.midjourney.com/omni-reference-oref/>:

- `--oref` is V7 and later; it replaced v6's `--cref`
- `--ow` runs 0–1000, default 100; above roughly 400 it fights `--stylize`
  and `--exp` and can make results worse
- omni-reference costs 2x GPU time and is incompatible with Fast, Draft and
  Conversational modes and with `--q 4`

**Permissively licensed collections** — where a licence explicitly allows
commercial reuse (CC0, MIT, and vendor prompt libraries published for the
purpose). Attribution recorded on the variant.

**Community reading, for technique not text.** Reddit, Discord, YouTube and
creator sites are useful for learning *what* people struggle with and which
techniques recur. Read them, learn the technique, write our own prompt, test
it. Never paste.

## Sources we do not use

**Scraped prompt text from social platforms.** Instagram, TikTok, Facebook,
Discord and Reddit all prohibit automated scraping in their terms. Crafted
prompts are plausibly copyrightable expression, so republishing them in a
paid product invites a takedown — and a public one, in a niche where
reputation is the whole moat.

**Anything we have not run ourselves.** This is the stricter rule and the
one that matters. A prompt we did not test cannot be given a verification
date without lying, and the gate would have to be weakened to admit it. The
gate is the product; weakening it to fill the library faster is trading the
only durable advantage for a week of catch-up.

## The workflow

1. Research the tool's current syntax from its own docs; update `FlagSpec`s,
   with the source URL and date in the comment.
2. Write the prompt, in that tool's native syntax, against a real goal.
3. Run it. Twice, with two different variable sets — the second run is what
   proves it generalises rather than being a lucky seed.
4. Capture the gallery images (see `assets/gallery/README.md`).
5. Write down how it fails. If you can't name a failure boundary, you
   haven't run it enough to publish it.
6. `flutter test` — the gate checks everything mechanical.
