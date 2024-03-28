defmodule KafkaexLagExporter.ConsumerOffsetFetcher do
  @moduledoc "Calculate summarized lag for each consumer group"

  alias KafkaexLagExporter.KafkaUtils

  # TODO fix type
  @spec get(KafkaexLagExporter.KafkaWrapper.Behaviour.endpoint()) :: %{
          lags: list(binary),
          sum: list(binary)
        }
  def get(endpoint) do
    consumer_group_names = KafkaUtils.get_consumer_group_names(endpoint)

    consumer_lags =
      KafkaUtils.topic_names_for_consumer_groups(endpoint, [], consumer_group_names)
      |> Enum.flat_map(&get_lag_per_topic(&1))

    consumer_lag_sum = get_lag_for_consumer_sum(consumer_lags)

    %{lags: consumer_lags, sum: consumer_lag_sum}
  end

  defp get_lag_per_topic({consumer_group, topics}) do
    Enum.map(topics, fn topic ->
      lag = KafkaUtils.lag(topic, consumer_group, :client1)
      {consumer_group, topic, lag}
    end)
  end

  defp get_lag_for_consumer_sum(lags_per_consumer_group) do
    Enum.map(lags_per_consumer_group, fn {consumer_group, topic, lag_per_partition} ->
      {consumer_group, topic, sum_topic_lag(lag_per_partition, 0)}
    end)
  end

  defp sum_topic_lag([], acc), do: acc
  defp sum_topic_lag([h | t], acc), do: sum_topic_lag(t, acc + elem(h, 1))
end
