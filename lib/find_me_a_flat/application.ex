defmodule FindMeAFlat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FindMeAFlatWeb.Telemetry,
      FindMeAFlat.Repo,
      {DNSCluster, query: Application.get_env(:find_me_a_flat, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:find_me_a_flat, :ash_domains),
         Application.fetch_env!(:find_me_a_flat, Oban)
       )},
      {Phoenix.PubSub, name: FindMeAFlat.PubSub},
      # Both are empty in S1. They start here so the shape of the tree is decided
      # once: S3 hangs the portal gate off Fetching, S5 hangs the bot off Bot.
      FindMeAFlat.Fetching.Supervisor,
      FindMeAFlat.Bot.Supervisor,
      # Start to serve requests, typically the last entry
      FindMeAFlatWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FindMeAFlat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FindMeAFlatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
