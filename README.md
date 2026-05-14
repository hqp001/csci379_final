# LearnAI — CSCI 379 Final Project

An AI-powered interactive learning platform. Enter any topic and the app generates a structured story with chapters, scenes, and quests (multiple choice, fill-in-the-blank, short answer). Complete scenes to earn XP and unlock the next one.

## Prerequisites

- **Elixir** 1.16+ and **Erlang/OTP** 26+ — install via [asdf](https://asdf-vm.com/) or [mise](https://mise.jdx.dev/)
- **PostgreSQL** — easiest via Docker (see below), or install locally on port **5433**
- **Node.js** 18+ (for asset building)

## Database setup

The app expects Postgres on **port 5433** (user `postgres`, password `postgres`). The easiest path is Docker:

```bash
docker compose up -d
```

Or if you have Postgres installed locally, make sure it's running on port 5433, or set `DB_PORT` in your `.env` to match your port.

## Environment variables

```bash
cp .env.example .env
```

Then fill in the values:

| Variable | Required | Notes |
|---|---|---|
| `OPENAI_API_KEY` | Yes | AI story generation. Need one for testing? Email me at **hungqpham212004@gmail.com** and I'll provide one. Otherwise get yours at [platform.openai.com](https://platform.openai.com). |
| `GOOGLE_CLIENT_ID` | Yes | Google OAuth. Create credentials at [console.cloud.google.com](https://console.cloud.google.com) → APIs & Services → Credentials. Redirect URI: `http://localhost:4000/auth/google/callback`. |
| `GOOGLE_CLIENT_SECRET` | Yes | Same Google OAuth credentials. |
| `RESEND_API_KEY` | **Prod only** | Not needed in dev — emails show up at `/dev/mailbox` locally. Only required for production deploys. |
| `DB_PORT` | No | Defaults to `5433`. |

## Running the app

```bash
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
