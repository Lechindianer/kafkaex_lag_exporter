defmodule KafkaexLagExporter.ConsumerOffsetFetcher do
  @moduledoc "Genserver implementation to calculate summarized lag for each consumer group"

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
    endpoints = clients[:kafka_client][:endpoints]

    Logger.info("Reveived Kafka endpoints: #{inspect(endpoints)}")

    Process.send_after(self(), :tick, @interval)
    {:ok, %{endpoints: endpoints}}
  end

  @impl true
  def handle_info(:tick, state) do
    [endpoint | _] = state.endpoints || [{"redpanda", 29_092}]

    consumer_group_names = get_consumer_group_names(endpoint)

    topic_names_for_consumer_groups =
      :brod.describe_groups(endpoint, [], consumer_group_names)
      |> get_topic_names_for_consumer_groups

    consumer_lags =
      topic_names_for_consumer_groups
      |> Enum.map(fn [consumer_group, topics] ->
        [consumer_group, get_lag_for_consumer(consumer_group, topics)]
      end)

    consumer_lag_sum = get_lag_for_consumer_sum(consumer_lags)

    KafkaexLagExporter.Metrics.group_lag_per_partition(endpoint, consumer_lags)
    KafkaexLagExporter.Metrics.group_sum_lag(endpoint, consumer_lag_sum)

    Process.send_after(self(), :tick, @interval)

    {:noreply, state}
  end

  defp get_consumer_group_names({host, port}) do
    [{_, groups} | _] = :brod.list_all_groups([{host, port}], [])

    groups
    |> Enum.filter(fn {_, _, protocol} -> protocol == "consumer" end)
    |> Enum.map(fn {_, group_name, "consumer"} -> group_name end)
  end

  defp get_topic_names_for_consumer_groups({:ok, group_descriptions}) do
    group_descriptions
    |> Enum.map(fn %{group_id: consumer_group, members: members} -> [consumer_group, members] end)
    |> Enum.map(fn [consumer_group, members] -> [consumer_group, get_topic_names(members)] end)
  end

  defp get_topic_names(members) do
    Enum.flat_map(members, fn member ->
      KafkaexLagExporter.TopicNameParser.parse_topic_names(member.member_assignment)
    end)
  end

  # TODO: test method for multiple topics
  defp get_lag_for_consumer(consumer_group, topics) do
    topics
    |> Enum.flat_map(fn topic ->
      KafkaexLagExporter.KafkaUtils.lag(topic, consumer_group, :client1)
    end)
  end

  # TODO: test method for multiple topics
  defp get_lag_for_consumer_sum(lags_per_consumer_group) do
    lags_per_consumer_group
    |> Enum.map(fn [topic, lag_per_partition] -> [topic, sum_topic_lag(lag_per_partition)] end)
  end

  defp sum_topic_lag(item, acc \\ 0)
  defp sum_topic_lag([], acc), do: acc
  defp sum_topic_lag([h | t], acc), do: sum_topic_lag(t, acc + elem(h, 1))
end
