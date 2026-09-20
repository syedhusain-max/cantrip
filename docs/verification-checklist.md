# Promoting a draft to the library

A draft in `lib/data/draft_library.dart` is a researched, plausible prompt
that nobody has run. Moving it into `lib/data/sample_library.dart` is the
moment it starts making a claim to users, so this is what that costs.

The app cannot show a draft — a test enforces it — and `DraftVariant` has no
`Freshness` field at all, so there is nowhere to write a verification date
you haven't earned.

## Per draft

**1. Run it from the example values, unchanged.**
Every variable has an `example`. Paste the prompt exactly as the app renders
it. If it needs edits to work, the prompt is wrong, not your inputs.

**2. Answer every line in `toVerify`.**
These are claims taken from vendor documentation — a number in a doc is not
the same as a number you observed. Where the real behaviour differs, the
observed value wins and the doc's claim goes in a guardrail.

**3. Run it again with a genuinely different variable set.**
Different subject, different colouring, different notes. The second run is
the one that proves the prompt generalises rather than that you got a lucky
seed. If it only works for the first set, say so in a guardrail or don't
publish it.

**4. Capture the gallery.**
1 before + 2 after, the two afters from the two different variable sets.
Naming and format are in `assets/gallery/README.md`.

**5. Write the failure boundary.**
At least one guardrail per step describing how it fails — not "may vary",
but the specific thing that goes wrong and the condition that causes it.
If you can't name one, you haven't run it enough. The gate enforces the
presence of a guardrail; only you can enforce that it is true.

**6. Move it.**
Convert the `DraftVariant` to a `PromptVariant` in `sample_library.dart`,
adding:

- `freshness: Freshness(verifiedOn: <the date you ran it>, verifiedBy: …,
  verifiedAgainstModelLabel: <the model you actually used>)`
- `gallery:` entries pointing at the files from step 4
- the guardrails from steps 3 and 5

Then delete it from `draft_library.dart`. Leaving it in both is the one
thing the tests will not let you do.

**7. `flutter test`.**
The publish gate checks everything mechanical: unfilled tokens, undocumented
variables, parameters the model doesn't accept, gallery counts, dates, model
labels, failure boundaries.

## What the gate cannot check

Whether the prompt is any good, and whether what you wrote down is true.
Those are the parts that make the library worth paying for, and they stay
with the person whose name is on it.
