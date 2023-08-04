defmodule KafkaexLagExporter.Metrics do
  @moduledoc "Metrics module is responsible for building and collecting kafka metrics"

  use PromEx.Plugin

  require Logger

  @kafka_event :kafka

  @impl true
  def manual_metrics(_opts) do
    clients = Application.get_env(:brod, :clients)
    [endpoint | _] = clients[:kafka_client][:endpoints] || [{"redpanda", 29_092}]

    Manual.build(
      :application_versions_manual_metrics,
      {__MODULE__, :kafka_metrics, [endpoint, []]},
      [
        last_value(
          [@kafka_event, :consumergroup, :group, :topic, :sum, :lag],
          event_name: [@kafka_event, :consumergroup, :group, :topic, :sum, :lag],
          description: "Sum of group offset lag across topic partitions",
          measurement: :lag,
          tags: [:cluster_name, :group, :topic]
        )
      ]
    )
  end

  @doc false
  def kafka_metrics({host, _port}, consumer_lags) do
    Enum.each(consumer_lags, fn [group_name, lag] ->
      :telemetry.execute(
        [@kafka_event, :consumergroup, :group, :topic, :sum, :lag],
        %{
          lag: lag
        },
        %{
          cluster_name: host,
          group: group_name,
          topic: []
        }
      )
    end)
  end
end
