defmodule KafkaexLagExporter.ConsumerOffsetRunner do
  @moduledoc "Genserver implementation to set offset metrics for consumer groups"

  use GenServer

  require Logger

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Logger.info("Starting #{__MODULE__}")

    clients = Application.get_env(:brod, :clients)
    endpoints = clients[:kafka_client][:endpoints] || [{"redpanda", 29_092}]

    interval =
      System.get_env("KAFKA_EX_INTERVAL", "5000")
      |> String.to_integer()

    Logger.info("Reveived Kafka endpoints: #{inspect(endpoints)}")
    Logger.info("Updating lag information every #{interval} milliseconds")

    Process.send_after(self(), :tick, interval)

    {:ok, %{endpoints: endpoints, interval: interval}}
  end

  @impl true
  def handle_info(:tick, state) do
    [endpoint | _] = state.endpoints
    interval = state.interval

    %{lags: lags, sum: lag_sum} = KafkaexLagExporter.ConsumerOffsetFetcher.get(endpoint)

    KafkaexLagExporter.Metrics.group_lag_per_partition(endpoint, lags)
    KafkaexLagExporter.Metrics.group_sum_lag(endpoint, lag_sum)

    Process.send_after(self(), :tick, interval)

    {:noreply, state}
  end
end
