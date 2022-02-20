defmodule KafkaexLagExporterWeb.Router do
  use KafkaexLagExporterWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", KafkaexLagExporterWeb do
    pipe_through :api
  end
end
