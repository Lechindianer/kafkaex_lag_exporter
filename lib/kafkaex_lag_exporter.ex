defmodule KafkaexLagExporter do

  @moduledoc """
  Supervisor to start the '__consumer__offsets' watcher child
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    consumer_group_opts = [
      # setting for the ConsumerGroup
      heartbeat_interval: 1_000,
      # this setting will be forwarded to the GenConsumer
      commit_interval: 1_000
    ]

    gen_consumer_impl = ConsumerOffsetsGenConsumer
    consumer_group_name = "offsets_group"
    topic_names = ["__consumer_offsets"]

    children = [
      supervisor(
        KafkaEx.ConsumerGroup,
        [gen_consumer_impl, consumer_group_name, topic_names, consumer_group_opts]
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
