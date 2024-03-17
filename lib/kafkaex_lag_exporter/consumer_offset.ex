defmodule KafkaexLagExporter.ConsumerOffset do
  @moduledoc "Genserver implementation to set offset metrics for consumer groups"

  use GenServer

  require Logger

  @interval 5_000

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Logger.info("Starting #{__MODULE__}")

    clients = Application.get_env(:brod, :clients)
    endpoints = clients[:kafka_client][:endpoints] || [{"redpanda", 29_092}]

    Logger.info("Reveived Kafka endpoints: #{inspect(endpoints)}")

    Process.send_after(self(), :tick, @interval)

    {:ok, %{endpoints: endpoints}}
  end

  @impl true
  def handle_info(:tick, state) do
    [endpoint | _] = state.endpoints

    {consumer_lags, consumer_lag_sum} = KafkaexLagExporter.ConsumerOffsetFetcher.get(endpoint)

    KafkaexLagExporter.Metrics.group_lag_per_partition(endpoint, consumer_lags)
    KafkaexLagExporter.Metrics.group_sum_lag(endpoint, consumer_lag_sum)

    Process.send_after(self(), :tick, @interval)

    {:noreply, state}
  end
end
