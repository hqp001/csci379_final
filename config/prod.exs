import Config

config :csci379_final, Csci379FinalWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  check_origin: ["https://eg.bucknell.edu"]

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile", callback_url: "https://eg.bucknell.edu/csci379e/auth/google/callback"]}
  ]

config :swoosh, api_client: Swoosh.ApiClient.Req
config :swoosh, local: false

config :logger, level: :info

# Enable mailbox preview so emails can be tested at /dev/mailbox
config :csci379_final, dev_routes: true
