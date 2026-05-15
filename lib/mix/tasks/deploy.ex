defmodule Mix.Tasks.Deploy do
  use Mix.Task

  require Logger

  @shortdoc "Commit and push code, then restart the Phoenix server on linuxremote3"

  def run([commit_message]) do
    # Load .env if present
    if File.exists?(".env") do
      File.read!(".env")
      |> String.split("\n", trim: true)
      |> Enum.reject(&String.starts_with?(&1, "#"))
      |> Enum.each(fn line ->
        case String.split(line, "=", parts: 2) do
          [key, val] -> System.put_env(String.trim(key), String.trim(val))
          _ -> :ok
        end
      end)
    end

    db_url = System.get_env("DATABASE_URL_PROD") ||
      raise "DATABASE_URL_PROD env var is missing"

    openai_key = System.get_env("OPENAI_API_KEY") ||
      raise "OPENAI_API_KEY env var is missing"

    google_client_id = System.get_env("GOOGLE_CLIENT_ID") ||
      raise "GOOGLE_CLIENT_ID env var is missing"

    google_client_secret = System.get_env("GOOGLE_CLIENT_SECRET") ||
      raise "GOOGLE_CLIENT_SECRET env var is missing"

    secret_key_base = System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE env var is missing"

    port = System.get_env("PORT") ||
      raise "PORT env var is missing"

    [_, _, _, database] = String.split(db_url, "/")

    Logger.debug("Pushing to remote branch...")
    System.cmd("git", ["add", "."], use_stdio: false)
    System.cmd("git", ["commit", "-m", commit_message], use_stdio: false)
    System.cmd("git", ["push"], use_stdio: false)

    Logger.debug("Deploying...")

    ssh_command = """
    echo "Loading environment..." && \
    module load elixir erlang > /dev/null || { exit 1; } && \
    cd ~/workspace/csci379_final && \
    echo "Resetting any local changes..." && \
    git reset --hard > /dev/null || { exit 1; } && \
    echo "Pulling latest code..." && \
    git pull > /dev/null || { exit 1; } && \
    echo "Stopping all running servers..." && \
    tmux kill-server >/dev/null || true && \
    echo "Loading dependencies..." && \
    MIX_ENV=prod mix deps.get --only prod > /dev/null || { exit 1; } && \
    echo "Compiling..." && \
    MIX_ENV=prod mix compile > /dev/null || { exit 1; } && \
    echo "Migrating database..." && \
    DATABASE_URL=#{db_url} OPENAI_API_KEY=#{openai_key} GOOGLE_CLIENT_ID=#{google_client_id} GOOGLE_CLIENT_SECRET=#{google_client_secret} SECRET_KEY_BASE=#{secret_key_base} PORT=#{port} MIX_ENV=prod mix ecto.migrate > /dev/null || { exit 1; } && \
    echo "Deploying assets..." && \
    MIX_ENV=prod mix assets.deploy > /dev/null || { exit 1; } && \
    echo "(Re)starting server in tmux..." && \
    tmux new -d -s #{database} \
    "export DATABASE_URL='#{db_url}' && \
    export OPENAI_API_KEY='#{openai_key}' && \
    export GOOGLE_CLIENT_ID='#{google_client_id}' && \
    export GOOGLE_CLIENT_SECRET='#{google_client_secret}' && \
    export SECRET_KEY_BASE='#{secret_key_base}' && \
    export PORT='#{port}' && \
    module load elixir erlang >/dev/null && \
    MIX_ENV=prod mix phx.server" && \
    echo "Deployment successful."
    """

    System.cmd("ssh", ["linuxremote3", "-t", "-o", "RemoteCommand=" <> ssh_command], use_stdio: false)
  end

  def run(_) do
    Logger.error("Usage: mix deploy <commit_message>")
  end
end
