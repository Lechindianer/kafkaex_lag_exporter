defmodule KafkaexLagExporter.ConsumerOffsetFetcher do
  @moduledoc """
  Genserver implementation to consume new messages on topic '__consumer_offsets'
  """

  use GenServer

  require Logger

  @interval 5_000

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def init(_) do
    Logger.info("Starting #{__MODULE__}")

    clients = Application.get_env(:brod, :clients)
    endpoints = clients[:kafka_client][:endpoints]

    Logger.info("Reveived Kafka endpoints: #{inspect(endpoints)}")

    Process.send_after(self(), :tick, @interval)
    {:ok, %{endpoints: endpoints}}
  end

  @impl true
  def handle_info(:tick, state) do
    consumer_groups = :brod.list_all_groups(state.endpoints, [])
    Logger.info("Consumer groups state: #{inspect(consumer_groups)}")

    Process.send_after(self(), :tick, @interval)

    {:noreply, state}
  end
end
