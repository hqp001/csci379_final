import Config

config :csci379_final, Csci379FinalWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  check_origin: ["https://eg.bucknell.edu"]

# Use local Swoosh adapter — no external email service needed
config :swoosh, api_client: false
config :swoosh, local: true

config :logger, level: :info
