# source code taken from https://github.com/reachfh/brod_group_subscriber_example

defmodule KafkaexLagExporter.KafkaUtils do
  @behaviour KafkaexLagExporter.KafkaUtils.Behaviour

  @moduledoc "Utility functions for dealing with Kafka"

  alias KafkaexLagExporter.KafkaWrapper.Behaviour, as: KafkaWrapper

  require Logger

  @default_client :client1

  def connection, do: connection(@default_client)
  @impl true
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

  @impl true
  def resolve_offsets(topic, type, client) do
    {endpoints, sock_opts} = connection(client)

    {:ok, partitions_count} = KafkaWrapper.get_partitions_count(client, topic)

    for i <- Range.new(0, partitions_count - 1),
        {:ok, offset} =
          KafkaWrapper.resolve_offset(endpoints, topic, i, type, sock_opts) do
      {i, offset}
    end
  end

  @impl true
  def fetch_committed_offsets(_topic, consumer_group, client) do
    {endpoints, sock_opts} = connection(client)

    {:ok, response} = KafkaWrapper.fetch_committed_offsets(endpoints, sock_opts, consumer_group)

    for r <- response,
        pr <- r[:partitions],
        do: {pr[:partition_index], pr[:committed_offset]}
  end

  @impl true
  def lag(topic, consumer_group, client) do
    offsets =
      resolve_offsets(topic, :latest, client)
      |> Enum.sort_by(fn {key, _value} -> key end)

    committed_offsets =
      fetch_committed_offsets(topic, consumer_group, client)
      |> Enum.sort_by(fn {key, _value} -> key end)

    for {{part, current}, {_part2, committed}} <- Enum.zip(offsets, committed_offsets) do
      {part, current - committed}
    end
  end

  @impl true
  def lag_total(topic, consumer_group, client) do
    for {_part, recs} <- lag(topic, consumer_group, client), reduce: 0 do
      acc -> acc + recs
    end
  end

  @impl true
  def get_consumer_group_names({host, port}) do
    [{_, groups} | _] = KafkaWrapper.list_all_groups([{host, port}], [])

    groups
    |> Enum.filter(fn {_, _, protocol} -> protocol === "consumer" end)
    |> Enum.map(fn {_, group_name, _} -> group_name end)
  end

  @impl true
  def get_consumer_group_info(endpoint, list \\ [], consumer_group_names) do
    {:ok, group_descriptions} = KafkaWrapper.describe_groups(endpoint, list, consumer_group_names)

    group_descriptions
    |> Enum.flat_map(fn %{group_id: consumer_group, members: members} ->
      get_member_info(members)
      |> Enum.map(fn {topic_names, consumer_id, member_host} ->
        {consumer_group, topic_names, consumer_id, member_host}
      end)
    end)
  end

  @spec get_member_info(
          list(%{client_host: binary, member_assignment: binary, member_id: binary})
        ) ::
          list({topic_names :: list(binary), consumer_id :: binary, member_host :: binary})
  defp get_member_info(members) do
    Enum.map(members, fn %{
                           client_host: member_host,
                           member_assignment: member_assignment,
                           member_id: consumer_id
                         } ->
      topic_names = KafkaexLagExporter.TopicNameParser.parse_topic_names(member_assignment)
      {topic_names, consumer_id, member_host}
    end)
  end
end
