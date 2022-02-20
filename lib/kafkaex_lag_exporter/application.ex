defmodule KafkaexLagExporter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    consumer_group_opts = [
      # setting for the ConsumerGroup
      heartbeat_interval: 1_000,
      # this setting will be forwarded to the GenConsumer
      commit_interval: 1_000
    ]

    gen_consumer_impl = KafkaexLagExporter.ConsumerOffsetsGenConsumer
    consumer_group_name = "offsets_group"
    topic_names = ["__consumer_offsets"]

    children = [
      KafkaexLagExporter.PromEx,
      # Start the Telemetry supervisor
      KafkaexLagExporterWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: KafkaexLagExporter.PubSub},
      # Start the Endpoint (http/https)
      KafkaexLagExporterWeb.Endpoint,
      # Start a worker by calling: KafkaexLagExporter.Worker.start_link(arg)
      # {KafkaexLagExporter.Worker, arg}
      %{
        id: KafkaEx.ConsumerGroup,
        start:
          {KafkaEx.ConsumerGroup, :start_link,
           [gen_consumer_impl, consumer_group_name, topic_names, consumer_group_opts]}
      }
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
