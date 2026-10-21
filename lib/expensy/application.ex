defmodule Expensy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExpensyWeb.Telemetry,
      Expensy.Repo,
      {DNSCluster, query: Application.get_env(:expensy, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Expensy.PubSub},
      # Start a worker by calling: Expensy.Worker.start_link(arg)
      # {Expensy.Worker, arg},
      # Start to serve requests, typically the last entry
      ExpensyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Expensy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExpensyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
