import Config

if config_env() == :dev do
  import Dotenvy
  source!([".env", System.get_env()]) |> System.put_env()

  if System.get_env("PHX_HOST") == "eg.bucknell.edu" do
    config :csci379_final, Csci379FinalWeb.Endpoint,
      url: [host: "eg.bucknell.edu", path: "/csci379e", port: 443, scheme: "https"],
      http: [
        ip: {0, 0, 0, 0, 0, 0, 0, 0},
        port: String.to_integer(System.get_env("PORT", "4505"))
      ],
      check_origin: ["https://eg.bucknell.edu"],
      live_reload: [patterns: []]
  end
end

if System.get_env("PHX_SERVER") do
  config :csci379_final, Csci379FinalWeb.Endpoint, server: true
end

if config_env() != :test do
  config :openai,
    api_key: System.fetch_env!("OPENAI_API_KEY"),
    http_options: [recv_timeout: 120_000]

  google_client_id =
    System.get_env("GOOGLE_CLIENT_ID") ||
      raise("environment variable GOOGLE_CLIENT_ID is missing.")

  google_client_secret =
    System.get_env("GOOGLE_CLIENT_SECRET") ||
      raise("environment variable GOOGLE_CLIENT_SECRET is missing.")

  google_callback_url =
    if System.get_env("PHX_HOST") == "eg.bucknell.edu" do
      "https://eg.bucknell.edu/csci379e/auth/google/callback"
    else
      "http://localhost:4000/auth/google/callback"
    end

  config :ueberauth, Ueberauth.Strategy.Google.OAuth,
    client_id: google_client_id,
    client_secret: google_client_secret

  config :ueberauth, Ueberauth,
    providers: [
      google: {Ueberauth.Strategy.Google, [default_scope: "email profile", callback_url: google_callback_url]}
    ]
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "environment variable DATABASE_URL is missing."

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing."

  port =
    System.get_env("PORT") ||
      raise "environment variable PORT is missing."

  config :csci379_final, Csci379Final.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "2")

  config :csci379_final, Csci379FinalWeb.Endpoint,
    url: [host: "eg.bucknell.edu", path: "/csci379e", port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: String.to_integer(port)],
    secret_key_base: secret_key_base

  resend_api_key =
    System.get_env("RESEND_API_KEY") ||
      raise "environment variable RESEND_API_KEY is missing."

  config :csci379_final, Csci379Final.Mailer,
    adapter: Swoosh.Adapters.Resend,
    api_key: resend_api_key
end
