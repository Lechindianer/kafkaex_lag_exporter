# source code taken from https://github.com/reachfh/brod_group_subscriber_example

defmodule KafkaexLagExporter.KafkaUtils do
  @behaviour KafkaexLagExporter.KafkaUtils.Behaviour

  @moduledoc "Utility functions for dealing with Kafka"

  alias KafkaexLagExporter.KafkaWrapper.Behaviour, as: KafkaWrapper

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
  def get_consumer_group_names(endpoint) do
    [{_, groups} | _] = KafkaWrapper.list_all_groups([endpoint], [])

    groups
    |> Enum.filter(fn {_, _, protocol} -> protocol === "consumer" end)
    |> Enum.map(fn {_, group_name, _} -> group_name end)
  end

  @impl true
  def get_consumer_group_info(endpoint, list \\ [], consumer_group_names) do
    {:ok, group_descriptions} = KafkaWrapper.describe_groups(endpoint, list, consumer_group_names)

    group_descriptions
    |> Enum.flat_map(fn %{group_id: consumer_group, members: members} ->
      get_member_info(consumer_group, members)
    end)
  end

  @impl true
  def lag(topic, consumer_group, client) do
    offsets =
      resolve_offsets(topic, client)
      |> Enum.sort_by(fn {key, _value} -> key end)

    committed_offsets =
      fetch_committed_offsets(topic, consumer_group, client)
      |> Enum.sort_by(fn {key, _value} -> key end)

    for {{part, current}, {_, committed}} <- Enum.zip(offsets, committed_offsets) do
      {part, current - committed}
    end
  end

  @spec resolve_offsets(binary, atom) :: list({non_neg_integer, integer})
  defp resolve_offsets(topic, client) do
    {endpoints, sock_opts} = connection(client)

    {:ok, partitions_count} = KafkaWrapper.get_partitions_count(client, topic)

    for i <- Range.new(0, partitions_count - 1),
        {:ok, offset} = KafkaWrapper.resolve_offset(endpoints, topic, i, :latest, sock_opts) do
      {i, offset}
    end
  end

  @spec fetch_committed_offsets(binary, binary, atom) ::
          list({non_neg_integer, non_neg_integer})
  defp fetch_committed_offsets(_topic, consumer_group, client) do
    {endpoints, sock_opts} = connection(client)

    {:ok, response} = KafkaWrapper.fetch_committed_offsets(endpoints, sock_opts, consumer_group)

    for r <- response, pr <- r[:partitions] do
      {pr[:partition_index], pr[:committed_offset]}
    end
  end

  @spec get_member_info(
          binary,
          list(%{client_host: binary, member_assignment: binary, member_id: binary})
        ) ::
          list(
            {consumer_group :: binary, topics :: list(binary), consumer_id :: binary,
             member_host :: binary}
          )
  defp get_member_info(consumer_group, members) do
    members
    |> Enum.map(fn %{
                     client_host: member_host,
                     member_assignment: member_assignment,
                     member_id: consumer_id
                   } ->
      topics = KafkaexLagExporter.TopicNameParser.parse_topic_names(member_assignment)
      {topics, consumer_id, member_host}
    end)
    |> Enum.map(fn {topics, consumer_id, member_host} ->
      {consumer_group, topics, consumer_id, member_host}
    end)
  end
end
