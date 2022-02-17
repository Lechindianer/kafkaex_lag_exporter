defmodule KafkaexLagExporter.MixProject do
  use Mix.Project

  def project do
    [
      app: :kafkaex_lag_exporter,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: { KafkaexLagExporter, [] },
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kafka_ex, "~> 0.12.1"},
    ]
  end
end
