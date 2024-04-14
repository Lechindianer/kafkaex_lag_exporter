defmodule KafkaexLagExporter.Metrics do
  @moduledoc "Metrics module is responsible for building and collecting kafka metrics"

  use PromEx.Plugin

  alias KafkaexLagExporter.ConsumerOffset

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
          tags: [:cluster_name, :group, :topic, :consumer_id, :member_host]
        ),
        last_value(
          [@kafka_event, :consumergroup, :group, :lag],
          event_name: [@kafka_event, :consumergroup, :group, :lag],
          description: "Group offset lag of a partition",
          measurement: :lag,
          tags: [:cluster_name, :group, :partition, :topic, :consumer_id, :member_host]
        )
      ]
    )
  end

  @spec group_sum_lag(
          KafkaexLagExporter.KafkaWrapper.Behaviour.endpoint(),
          list(ConsumerOffset.t())
        ) :: :ok
  @doc false
  def group_sum_lag({host, _port}, consumer_offsets) do
    Enum.each(consumer_offsets, fn %ConsumerOffset{} = consumer_offset ->
      lag = elem(consumer_offset.lag, 1)

      :telemetry.execute(
        [@kafka_event, :consumergroup, :group, :topic, :sum, :lag],
        %{lag: lag},
        %{
          cluster_name: host,
          group: consumer_offset.consumer_group,
          topic: consumer_offset.topic,
          consumer_id: consumer_offset.consumer_id,
          member_host: consumer_offset.member_host
        }
      )
    end)
  end

  @spec group_lag_per_partition(
          KafkaexLagExporter.KafkaWrapper.Behaviour.endpoint(),
          list(ConsumerOffset.t())
        ) :: :ok
  @doc false
  def group_lag_per_partition({host, _port}, consumer_offsets) do
    Enum.each(consumer_offsets, fn %ConsumerOffset{} = consumer_offset ->
      Enum.each(consumer_offset.lag, fn {partition, lag} ->
        :telemetry.execute(
          [@kafka_event, :consumergroup, :group, :lag],
          %{lag: lag},
          %{
            cluster_name: host,
            group: consumer_offset.consumer_group,
            partition: partition,
            topic: consumer_offset.topic,
            consumer_id: consumer_offset.consumer_id,
            member_host: consumer_offset.member_host
          }
        )
      end)
    end)
  end
end
