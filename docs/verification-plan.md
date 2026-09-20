# The verification session

Seven drafts, five goals, four tools. This is the running order, grouped so
you work one tool at a time instead of switching accounts seven times.

Everything mechanical is already checked — flags valid for the declared
model, tokens matching declared variables, `bindsTo` pointing at real
contract keys, taxonomy ids that exist. What's left is the part only a
person with an account can do.

## Midjourney v7 — three drafts, one session

| Draft | Goal | The thing to find out |
|---|---|---|
| `var_mj_oref_avatar` | Consistent avatar | Does `--ow 150` hold a face? Where does style actually stop responding? |
| `var_mj_product_hero` | Product hero shot | Does `--ow 400` keep **label text** legible? This is the make-or-break |
| `var_mj_style_lock` | Campaign style lock | Find a style code worth keeping and write it down |

Do these together — same subscription, same session, and the `--ow`
findings from the first inform the second.

**Before you start:** host two reference images publicly (one face, one
product). `--oref` takes a URL, not an upload, and a private link fails
silently — you get a generic result rather than an error, which is the
kind of failure that wastes an hour.

## OpenArt — one draft

`var_oa_product_hero` trains the product as an object. Two things matter:
confirm the current minimum training images (docs say 4–20 and the floor
moves), and find out whether object training holds a **printed label** or
only silhouette and colour. If it's the latter, the variant is still
useful but the summary has to say so.

This is also the cross-tool pair: the same goal as `var_mj_product_hero`,
so switching tools on that prompt is the tool switcher demonstrating
itself. Run both with the same product and the demo writes itself.

## Gamma — three drafts

| Draft | Format | The thing to find out |
|---|---|---|
| `var_gamma_deck_from_notes` | presentation | Does the reorder command reorder, or silently rewrite? |
| `var_gamma_board_update` | document | Does document format keep prose, or collapse to bullets? |
| `var_gamma_launch_page` | website | Does it produce page structure, or stacked slides? |

**Test the board update with a month that went badly.** Generators smooth
bad news, and the prompt's "worst news first, do not soften" instruction is
either doing work or it isn't — a tidy month won't tell you.

## For every draft, regardless

1. Run it from the example values, unchanged.
2. Run it again with a genuinely different variable set.
3. Capture 1 before + 2 after, the afters from the two different sets.
4. Write the failure boundary you actually saw.
5. Promote it per `docs/verification-checklist.md`.

## What to expect

Some of these will be wrong. That's what the session is for — a draft that
survives contact unchanged is suspicious. When documentation and observation
disagree, observation wins and the doc's claim becomes a guardrail.

If a draft turns out not to work at all, delete it. Seven drafts is not a
target to hit; the library is better with four prompts that work than seven
where three are hopeful.
