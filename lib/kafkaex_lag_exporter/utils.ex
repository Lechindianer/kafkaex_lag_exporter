# source code taken from https://github.com/reachfh/brod_group_subscriber_example

defmodule KafkaexLagExporter.KafkaUtils do
  @moduledoc "Utility functions for dealing with Kafka"

  @default_client :client1

  @type endpoint() :: {host :: atom(), port :: non_neg_integer()}

  def connection, do: connection(@default_client)
  @spec connection(atom) :: {list({charlist, non_neg_integer}), Keyword.t()}
  def connection(client) do
    clients = Application.get_env(:brod, :clients)
    config = clients[client]

    endpoints = config[:endpoints] || [{~c"localhost", 9092}]

    sock_opts =
      case Keyword.fetch(config, :ssl) do
        {:ok, ssl_opts} ->
          [ssl: ssl_opts]

        :error ->
          []
      end

    {endpoints, sock_opts}
  end

  @spec resolve_offsets(binary(), :earliest | :latest, atom()) ::
          list({non_neg_integer(), integer()})
  def resolve_offsets(topic, type, client) do
    {endpoints, sock_opts} = connection(client)

    {:ok, partitions_count} = :brod.get_partitions_count(client, topic)

    for i <- Range.new(0, partitions_count - 1),
        {:ok, offset} = :brod.resolve_offset(endpoints, topic, i, type, sock_opts) do
      {i, offset}
    end
  end

  @spec fetch_committed_offsets(binary(), binary(), atom()) ::
          {non_neg_integer(), non_neg_integer()}
  def fetch_committed_offsets(_topic, consumer_group, client) do
    {endpoints, sock_opts} = connection(client)
    {:ok, response} = :brod.fetch_committed_offsets(endpoints, sock_opts, consumer_group)

    for r <- response,
        pr <- r[:partitions],
        do: {pr[:partition_index], pr[:committed_offset]}
  end

  @spec lag(binary(), binary(), atom()) :: list({non_neg_integer(), integer()})
  def lag(topic, consumer_group, client) do
    offsets = resolve_offsets(topic, :latest, client)
    committed_offsets = fetch_committed_offsets(topic, consumer_group, client)

    for {{part, current}, {_part2, committed}} <- Enum.zip(offsets, committed_offsets) do
      {part, current - committed}
    end
  end

  @spec lag_total(binary(), binary(), atom()) :: non_neg_integer()
  def lag_total(topic, consumer_group, client) do
    for {_part, recs} <- lag(topic, consumer_group, client), reduce: 0 do
      acc -> acc + recs
    end
  end
end
