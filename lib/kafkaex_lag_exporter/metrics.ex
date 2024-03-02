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
      {__MODULE__, :group_sum_lag, [endpoint, []]},
      [
        last_value(
          [@kafka_event, :consumergroup, :group, :topic, :sum, :lag],
          event_name: [@kafka_event, :consumergroup, :group, :topic, :sum, :lag],
          description: "Sum of group offset lag across topic partitions",
          measurement: :lag,
          # TODO: add more tags like member_host, consumer_id, client_id, ...
          tags: [:cluster_name, :group, :topic]
        ),
        last_value(
          [@kafka_event, :consumergroup, :group, :lag],
          event_name: [@kafka_event, :consumergroup, :group, :lag],
          description: "Group offset lag of a partition",
          measurement: :lag,
          # TODO: add more tags like member_host, consumer_id, client_id, ...
          tags: [:cluster_name, :group, :partition, :topic]
        )
      ]
    )
  end

  @doc false
  def group_sum_lag({host, _port}, consumer_lags) do
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

  @doc false
  def group_lag_per_partition({host, _port}, consumer_lags) do
    Enum.each(consumer_lags, fn [group_name, lags] ->
      Enum.each(lags, fn {partition, lag} ->
        :telemetry.execute(
          [@kafka_event, :consumergroup, :group, :lag],
          %{
            lag: lag
          },
          %{
            cluster_name: host,
            group: group_name,
            partition: partition,
            topic: []
          }
        )
      end)
    end)
  end
end
