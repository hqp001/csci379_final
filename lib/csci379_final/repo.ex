defmodule Csci379Final.Repo do
  use Ecto.Repo,
    otp_app: :csci379_final,
    adapter: Ecto.Adapters.Postgres
end
