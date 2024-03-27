defmodule KafkaexLagExporter.MixProject do
  use Mix.Project

  def project do
    [
      app: :kafkaex_lag_exporter,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {KafkaexLagExporter.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.6"},
      {:telemetry_metrics, "~> 0.6.1"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.4.0"},
      {:plug_cowboy, "~> 2.6.1"},
      {:credo, "~> 1.7.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:patch, "~> 0.13.0", only: :test},
      {:brod, "~> 3.17.0"},
      {:prom_ex, "~> 1.8.0"},
      {:telemetry, "~> 1.2"}
    ]
  end
end
