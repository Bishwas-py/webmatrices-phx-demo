defmodule WebmatricesPhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WebmatricesPhoenixWeb.Telemetry,
      WebmatricesPhoenix.Repo,
      {DNSCluster, query: Application.get_env(:webmatrices_phoenix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WebmatricesPhoenix.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: WebmatricesPhoenix.Finch},
      # Start a worker by calling: WebmatricesPhoenix.Worker.start_link(arg)
      # {WebmatricesPhoenix.Worker, arg},
      # Start to serve requests, typically the last entry
      WebmatricesPhoenixWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebmatricesPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WebmatricesPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
