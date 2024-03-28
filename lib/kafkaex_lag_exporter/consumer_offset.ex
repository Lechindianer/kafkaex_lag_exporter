defmodule KafkaexLagExporter.ConsumerOffset do
  @moduledoc "Struct holding all relevant telemetry information of consumers"

  @type t :: %__MODULE__{
          consumer_group: binary,
          topic: binary,
          lag: list({partition :: non_neg_integer, lag :: non_neg_integer}),
          consumer_id: binary,
          member_host: binary
        }

  defstruct consumer_group: "",
            topic: "",
            lag: [],
            consumer_id: "",
            member_host: ""
end
