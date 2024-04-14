defmodule KafkaexLagExporter.KafkaUtils.Behaviour do
  @moduledoc false

  @callback connection(atom) :: {list({charlist, non_neg_integer}), Keyword.t()}

  @callback get_consumer_group_names({host :: atom, port :: non_neg_integer}) :: list(binary)

  @callback get_consumer_group_info(
              {host :: atom, port :: non_neg_integer},
              list(binary),
              list(binary)
            ) :: list({consumer_group :: binary, topics :: list(binary)})

  @callback lag(binary, binary, atom) :: list({non_neg_integer, integer})

  def connection(client), do: impl().connection(client)

  def get_consumer_group_names(endpoint), do: impl().get_consumer_group_names(endpoint)

  def get_consumer_group_info(endpoint, list, consumer_group_names),
    do: impl().get_consumer_group_info(endpoint, list, consumer_group_names)

  def lag(topic, consumer_group, client), do: impl().lag(topic, consumer_group, client)

  def fetch_committed_offsets(topic, consumer_group, client),
    do: impl().fetch_committed_offsets(topic, consumer_group, client)

  defp impl,
    do: Application.get_env(:kafkaex_lag_exporter, :kafka_utils, KafkaexLagExporter.KafkaUtils)
end
