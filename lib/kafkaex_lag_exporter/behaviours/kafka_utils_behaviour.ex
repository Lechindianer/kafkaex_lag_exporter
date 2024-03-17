defmodule KafkaexLagExporter.KafkaUtils.Behaviour do
  @moduledoc false

  @callback connection(atom) :: {list({charlist, non_neg_integer}), Keyword.t()}

  @callback resolve_offsets(binary, :earliest | :latest, atom) ::
              list({non_neg_integer, integer})

  @callback fetch_committed_offsets(binary, binary, atom) ::
              list({non_neg_integer, non_neg_integer})

  @callback lag(binary, binary, atom) :: list({non_neg_integer, integer})

  @callback lag_total(binary, binary, atom) :: non_neg_integer

  @callback get_consumer_group_names({host :: atom, port :: non_neg_integer}) :: list(binary)

  @callback topic_names_for_consumer_groups(
              {host :: atom, port :: non_neg_integer},
              list(binary),
              list(binary)
            ) :: list(binary)

  def connection(client), do: impl().connection(client)

  def resolve_offsets(topic, type, client), do: impl().resolve_offsets(topic, type, client)

  def fetch_committed_offsets(topic, consumer_group, client),
    do: impl().fetch_committed_offsets(topic, consumer_group, client)

  def lag(topic, consumer_group, client), do: impl().lag(topic, consumer_group, client)

  def lag_total(topic, consumer_group, client),
    do: impl().lag_total(topic, consumer_group, client)

  def get_consumer_group_names({host, port}), do: impl().get_consumer_group_names({host, port})

  def topic_names_for_consumer_groups(endpoint, list, consumer_group_names),
    do: impl().topic_names_for_consumer_groups(endpoint, list, consumer_group_names)

  defp impl,
    do: Application.get_env(:kafkaex_lag_exporter, :kafka_utils, KafkaexLagExporter.KafkaUtils)
end
