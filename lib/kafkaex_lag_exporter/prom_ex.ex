defmodule KafkaexLagExporter.PromEx do
  @moduledoc false

  use PromEx, otp_app: :kafkaex_lag_exporter

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      # PromEx built in plugins
      Plugins.Application,
      Plugins.Beam,
      # {Plugins.Phoenix, router: KafkaexLagExporterWeb.Router, endpoint: KafkaexLagExporterWeb.Endpoint},
      # Plugins.Ecto,
      # Plugins.Oban,
      # Plugins.PhoenixLiveView,
      # Plugins.Absinthe,
      # Plugins.Broadway,

      # Add your own PromEx metrics plugins
      KafkaexLagExporter.Metrics
    ]
  end
end
