defmodule KafkaexLagExporter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KafkaexLagExporter.PromEx,
      # Start the Telemetry supervisor
      KafkaexLagExporterWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: KafkaexLagExporter.PubSub},
      # Start the Endpoint (http/https)
      KafkaexLagExporterWeb.Endpoint,
      KafkaexLagExporter.ConsumerOffset
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KafkaexLagExporter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KafkaexLagExporterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
