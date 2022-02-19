defmodule ConsumerOffsetsGenConsumer do
  use KafkaEx.GenConsumer

  alias KafkaEx.Protocol.Fetch.Message

  require Logger

  def handle_message_set(message_set, state) do
    for %Message{key: key, offset: offset} <- message_set do
      consumer_group = get_consumer_group(key)

      Logger.info("consumer_group '#{consumer_group}' has offset '#{offset}'}")
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
