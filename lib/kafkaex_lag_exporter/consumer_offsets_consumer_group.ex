defmodule KafkaexLagExporter.ConsumerOffsetsGenConsumer do
  @moduledoc """
  Genserver implementation to consume new messages on topic '__consumer_offsets'
  """

  use KafkaEx.GenConsumer

  alias KafkaEx.Protocol.Fetch.Message

  require Logger

  def init(_topic, _partition, _extra_args) do
    {:ok, %{}}
  end

  def get() do
    GenServer.cast(__MODULE__, {:get})
  end

  def handle_call({:get}, _from, state) do
    {:reply, state}
  end

  def handle_call({:push, topic, offset}, _from, state) do
    new_state = Map.put(state, topic, offset)

    #    IO.puts "new state"
    #    IO.inspect new_state

    {:reply, new_state}
  end

  def handle_message_set(message_set, state) do
    for %Message{key: key, offset: offset} <- message_set do
      consumer_group = get_consumer_group(key)

      Logger.info("consumer_group '#{consumer_group}' has offset '#{offset}'}")

      # GenServer.call(__MODULE__, {:push, consumer_group, offset})
    end

    {:async_commit, state}
  end

  defp get_consumer_group(<<prefix, version, postfix::binary-size(2), consumer_group::binary>>) do
    Logger.debug(fn -> "prefix: " <> inspect(prefix) end)
    Logger.debug(fn -> "version: " <> inspect(version) end)
    Logger.debug(fn -> "postfix: " <> inspect(postfix) end)

    consumer_group
  end
end
