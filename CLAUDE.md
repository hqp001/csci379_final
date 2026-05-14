# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
mix setup              # install deps, create DB, migrate, build assets
mix dev                # alias for mix phx.server
mix test               # run all tests (auto-creates/migrates test DB)
mix test test/path/to/file_test.exs          # run a single test file
mix test test/path/to/file_test.exs:42       # run a single test by line
mix precommit          # compile --warnings-as-errors, format, unused deps, full test suite
mix ecto.reset         # drop + recreate + migrate dev DB
mix format             # format all Elixir files
```

Dev server runs at `http://localhost:4000`. Dev mailbox at `http://localhost:4000/dev/mailbox`. LiveDashboard at `http://localhost:4000/dev/dashboard`.

Database is PostgreSQL on **port 5433** (non-standard): `postgres/postgres`, database `csci379_final_dev`.

## Architecture

### Contexts

- `Csci379Final.Accounts` — phx.gen.auth + Google OAuth (Ueberauth). Auth state flows through a `Scope` struct (`current_scope`) assigned to every LiveView socket via `on_mount`.
- `Csci379Final.Stories` — story/chapter/scene/quest CRUD, plus async AI story generation. Story generation runs in a `Task.Supervisor` child task and broadcasts progress over PubSub on `"story:#{id}"`.
- `Csci379Final.Learning` — (Slice 4, not yet built) quest attempts, scene completions, XP, unlocking next scene.
- `Csci379Final.AI` — thin facade delegating to a configured adapter.

### AI port/adapter pattern (hexagonal)

`AI.GeneratorPort` defines two callbacks: `generate_story/1` and `grade_answer/2`. The active adapter is selected at compile time via config:

```elixir
config :csci379_final, ai_adapter: Csci379Final.AI.OpenAIAdapter
```

- `OpenAIAdapter` — calls GPT-4o-mini via the `:openai` hex package, expects `OPENAI_API_KEY` in env.
- `StubAdapter` — returns hardcoded Roman Empire data; safe for dev/test without an API key.

To switch adapters in dev, override in `config/dev.exs`. Tests should use `StubAdapter`.

### LiveView pages

| Route | Module | Status |
|---|---|---|
| `/dashboard` | `DashboardLive` | Done |
| `/stories/new` | `StoryLive.New` | Done |
| `/stories/:id` | `StoryLive.Show` | Done |
| `/stories/:story_id/scenes/:id` | `SceneLive.Show` | Stub |
| `/profile` | `ProfileLive` | Stub |

All LiveViews are in the `:authenticated` live session (requires login).

### Data model

```
stories (user_id, title, topic, status: generating|ready|failed)
  └── chapters (story_id, position)
        └── scenes (chapter_id, position, is_locked)
              └── quests (scene_id, type: multiple_choice|fill_blank|short_answer, options: jsonb)
scene_completions (user_id, scene_id, xp_earned)   — unique per user+scene
quest_attempts    (user_id, quest_id, user_answer, is_correct, ai_feedback)
```

### Story generation flow

1. `Stories.create_story_async/2` inserts a `:generating` story record.
2. `Stories.start_generation/2` spawns a supervised Task.
3. Task calls `AI.generate_story/1` → parses JSON → `insert_tree/2` walks chapters/scenes/quests.
4. Progress steps broadcast on `"story:#{id}"` via `Phoenix.PubSub`.
5. On success: story status set to `:ready`, `{:story_ready, id}` broadcast. On failure: `:failed`.

### Env vars

Loaded by `dotenvy`. All required vars must be present — no fallback defaults anywhere. If a var is missing the app raises at startup.
