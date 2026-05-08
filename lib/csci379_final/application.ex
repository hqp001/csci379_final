defmodule Csci379Final.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Csci379FinalWeb.Telemetry,
      Csci379Final.Repo,
      {DNSCluster, query: Application.get_env(:csci379_final, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Csci379Final.PubSub},
      {Task.Supervisor, name: Csci379Final.TaskSupervisor},
      Csci379FinalWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Csci379Final.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Csci379FinalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
