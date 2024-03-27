defmodule KafkaexLagExporter.TopicNameParser do
  @moduledoc "Parse Kafka internal member assignment payload in order to find which topics belong to the consumer group"

  @invalid_topic_characters ~r/[^[:alnum:]\-\._]/

  @spec parse_topic_names(binary) :: list(binary)
  def parse_topic_names(member_assignment) do
    member_assignment
    |> String.chunk(:printable)
    |> Enum.drop(1)
    |> Enum.take_every(2)
    |> Enum.map(fn topic_name -> Regex.replace(@invalid_topic_characters, topic_name, "") end)
  end
end
