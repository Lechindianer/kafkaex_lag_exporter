defmodule KafkaexLagExporter.ConsumerOffsetFetcher do
  @moduledoc "Calculate summarized lag for each consumer group"

  alias KafkaexLagExporter.ConsumerOffset
  alias KafkaexLagExporter.KafkaUtils

  # TODO fix type
  @spec get(KafkaexLagExporter.KafkaWrapper.Behaviour.endpoint()) :: %{
          lags: list(binary),
          sum: list(binary)
        }
  def get(endpoint) do
    consumer_group_names = KafkaUtils.get_consumer_group_names(endpoint)

    consumer_lags =
      KafkaUtils.get_consumer_group_info(endpoint, [], consumer_group_names)
      |> Enum.flat_map(&get_lag_per_topic(&1))

    consumer_lag_sum = get_lag_for_consumer_sum(consumer_lags)

    %{lags: consumer_lags, sum: consumer_lag_sum}
  end

  @spec get_lag_per_topic(
          {consumer_group :: binary, topics :: list(binary), consumer_id :: binary,
           member_host :: binary}
        ) :: list(ConsumerOffset.t())
  defp get_lag_per_topic({consumer_group, topics, consumer_id, member_host}) do
    Enum.map(topics, fn topic ->
      lag = KafkaUtils.lag(topic, consumer_group, :client1)

      %ConsumerOffset{
        consumer_group: consumer_group,
        topic: topic,
        lag: lag,
        consumer_id: consumer_id,
        member_host: member_host
      }
    end)
  end

  @spec get_lag_per_topic(list(ConsumerOffset.t())) :: list(ConsumerOffset.t())
  defp get_lag_for_consumer_sum(lags_per_consumer_group) do
    Enum.map(lags_per_consumer_group, fn consumer_offset ->
      lag_sum = sum_topic_lag(consumer_offset.lag, 0)
      %ConsumerOffset{consumer_offset | lag: {0, lag_sum}}
    end)
  end

  defp sum_topic_lag([], acc), do: acc
  defp sum_topic_lag([h | t], acc), do: sum_topic_lag(t, acc + elem(h, 1))
end
