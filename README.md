# LearnAI — CSCI 379 Final Project

An AI-powered interactive learning platform. Enter any topic and the app generates a structured story with chapters, scenes, and quests (multiple choice, fill-in-the-blank, short answer). Complete scenes to earn XP and unlock the next one.

## Running the app

```bash
cp .env.example .env        # fill in OPENAI_API_KEY, RESEND_API_KEY, GOOGLE_CLIENT_ID/SECRET
mix setup                   # install deps, create DB, migrate, build assets
mix dev                     # start server at http://localhost:4000
```

Dev mailbox: `http://localhost:4000/dev/mailbox`
LiveDashboard: `http://localhost:4000/dev/dashboard`

## Running tests

```bash
mix test                    # run all tests
mix test --cover            # with coverage report
```

## Chosen optional items (7 of 13)

| # | Item | Notes |
|---|------|-------|
| 1 | **Google OAuth** | Sign in with Google via Ueberauth, alongside email/password |
| 2 | **Associative Schemas** | 1:n chain (Story → Chapter → Scene → Quest); n:m via `scene_completions` (User ↔ Scene) |
| 3 | **Embedded Schemas** | `Quest.options` uses `embeds_many Quest.Option` — typed `{key, text}` structs stored as JSONB |
| 4 | **File Uploads** | Upload a `.txt`/`.md` reference document on the New Story page; content is appended to the AI prompt |
| 5 | **Displaying Charts** | Chart.js line chart on the Profile page tracking cumulative XP over time |
| 6 | **Mailer for Transactional Emails** | Welcome email sent on registration via Swoosh + Resend; visible at `/dev/mailbox` in dev |
| 7 | **Internationalization** | ≥90% of UI translated into Spanish (ES) via Gettext; EN/ES toggle in the navbar persisted to session |

## Architecture

- **Contexts:** `Accounts` (auth + OAuth), `Stories` (story/chapter/scene/quest CRUD + async AI generation), `Learning` (attempts, completions, XP), `AI` (port/adapter pattern)
- **AI adapters:** `ClaudeAdapter` (production via OpenAI-compatible API), `StubAdapter` (dev/test, hardcoded Roman Empire data)
- **Real-time:** Story generation progress streamed via PubSub to `StoryLive.New`
- **LiveViews:** Dashboard, StoryLive.New, StoryLive.Show, SceneLive.Show, ProfileLive
