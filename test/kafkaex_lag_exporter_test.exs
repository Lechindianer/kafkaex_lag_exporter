defmodule KafkaexLagExporterTest do
  use ExUnit.Case
  doctest KafkaexLagExporter

  test "greets the world" do
    assert KafkaexLagExporter.hello() == :world
  end
end
