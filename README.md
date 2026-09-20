# Cantrip

A cross-platform library of tested prompts and multi-step recipes for AI
creative tools. One Flutter codebase, running on Android and the web.

The idea it's built around: **be tool-agnostic about the goal and
tool-specific about the prompt.** You pick what you want to make — a
consistent avatar, a product video, a pitch deck — and the app hands you the
exact prompt in that tool's native syntax, with the variables left to fill
in. The same goal carries variants for different tools, so switching from
Higgsfield to OpenArt keeps what you typed and swaps the prompt around it.

## Running it

Requires Flutter 3.47.4 (the version CI pins). With the SDK on your `PATH`:

```bash
flutter pub get
flutter analyze          # must be clean
flutter test             # must all pass
flutter run -d chrome    # or a connected Android device
```

The app runs fully offline with no backend and no account. To enable
cross-device sync, create a Supabase project, run
`supabase/migrations/0001_user_data.sql` in its SQL editor, and pass the
project's credentials at build time:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

With those undefined the app simply stays local: no account section, no
network. A missing key degrades the app rather than breaking it.

## How it's put together

```
Goal  (tool-agnostic: title, use case, niche, output type, input contract)
 └── PromptVariant  (one per tool: native syntax, model label, steps)
      ├── PromptVariable  (bindsTo → a key on the goal's contract)
      └── PromptStep      (inputs / produces — an explicit dependency graph)
```

- **Prompt content ships in the app bundle**, not behind an API. The backend
  only ever holds what a user did: their saved copies, folders and reports.
- **Tools and categories are data**, in `lib/data/`. Adding an AI tool is a
  registry entry — no screen, filter or model change.
- **`bindsTo` is what makes the tool switcher work.** It maps a variant's
  tool-native variable onto a shared key on the goal, which is the only
  reason switching tools can keep what you typed.
- **Prompts go stale on their own.** Each one carries a verification date and
  decays from verified → aging → needs review, and flips to broken when
  enough people report it broken. Stale entries sort below healthy ones
  rather than disappearing.
- **Every screen has a URL** (`go_router`, hash strategy), so a prompt can be
  linked and shared.

## The publishing gate

`test/publish_gate_test.dart` runs on every commit and blocks any prompt with
an unfilled token, an undocumented variable, a parameter its target tool
doesn't accept, too few before/after images, a missing verification date, or
no stated failure boundary. It exists because a prompt library is only worth
opening if the prompts still work — and the way they stop working is a tool
update nobody noticed.

## Layout

```
lib/
  data/      tool and taxonomy registries, bundled prompt content
  models/    goal, prompt variant, step, variable, freshness, fork, folder
  state/     library state, local + synced stores, auth
  router/    every route and the path helpers
  screens/   home, library, create, prompt detail, recipe runner, saved,
             folder, settings, sign in
  widgets/   prompt card, tool badge, freshness pill, step card, …
  l10n/      all UI copy, one file, keyed by locale
supabase/
  migrations/  schema and row-level security
```

## Deploying

`.github/workflows/deploy-web.yml` builds and publishes to GitHub Pages on
every push to `main`. Supabase credentials come from repository secrets; with
them unset the deploy still succeeds and ships the local-only app.
