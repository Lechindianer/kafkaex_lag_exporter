defmodule KafkaexLagExporter.ConsumerOffsetFetcher do
  @moduledoc "Genserver implementation to calculate summarized lag for each consumer group"

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
    [endpoint | _] = state.endpoints || [{"redpanda", 29_092}]

    consumer_group_names = get_consumer_group_names(endpoint)

    consumer_lags =
      :brod.describe_groups(endpoint, [], consumer_group_names)
      |> get_consumer_lags

    Logger.info("Consumer lags: #{inspect(consumer_lags)}")

    Process.send_after(self(), :tick, @interval)

    {:noreply, state}
  end

  defp get_consumer_group_names({host, port}) do
    [{_, groups} | _] = :brod.list_all_groups([{host, port}], [])

    groups
    |> Enum.filter(fn {_, _, protocol} -> protocol == "consumer" end)
    |> Enum.map(fn {_, group_name, "consumer"} -> group_name end)
  end

  defp get_consumer_lags({:ok, group_descriptions}) do
    group_descriptions
    |> Enum.map(fn %{group_id: consumer_group, members: members} ->
      [consumer_group, members]
    end)
    |> Enum.map(fn [consumer_group, members] -> [consumer_group, get_topic_names(members)] end)
    |> Enum.map(fn [consumer_group, topics] ->
      [consumer_group, get_lag_for_consumer(consumer_group, topics)]
    end)
  end

  defp get_consumer_lags({_, _}), do: []

  defp get_topic_names(members) do
    Enum.flat_map(members, fn member ->
      KafkaexLagExporter.TopicNameParser.parse_topic_names(member.member_assignment)
    end)
  end

  defp get_lag_for_consumer(consumer_group, topics) do
    topics
    |> Enum.reduce(0, fn topic, acc ->
      acc + KafkaexLagExporter.KafkaUtils.lag_total(topic, consumer_group, :client1)
    end)
  end
end
