import Config

config :csci379_final, Csci379FinalWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  check_origin: ["https://eg.bucknell.edu"]

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile", callback_url: "https://eg.bucknell.edu/csci379e/auth/google/callback"]}
  ]

# Use local Swoosh adapter — no external email service needed
config :swoosh, api_client: false
config :swoosh, local: true

config :logger, level: :info
