defmodule InterestSpotlight.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      InterestSpotlightWeb.Telemetry,
      InterestSpotlight.Repo,
      {DNSCluster,
       query: Application.get_env(:interest_spotlight, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: InterestSpotlight.PubSub},
      InterestSpotlightWeb.Presence,
      # Start a worker by calling: InterestSpotlight.Worker.start_link(arg)
      # {InterestSpotlight.Worker, arg},
      # Start to serve requests, typically the last entry
      InterestSpotlightWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: InterestSpotlight.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    InterestSpotlightWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
