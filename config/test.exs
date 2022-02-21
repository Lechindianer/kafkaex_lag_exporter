import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :kafkaex_lag_exporter, KafkaexLagExporterWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "+3V7k0WsFksjqGwm5O54NJQX4Sz9LLr8CSJp+4X6UOXBX6IUwzMOqrRQOsziQ6mv",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :kafka_ex,
  disable_default_worker: true

System.put_env("KAFKA_BROKER1_HOST", "localhost")
System.put_env("KAFKA_BROKER2_HOST", "localhost")
System.put_env("KAFKA_BROKER3_HOST", "localhost")
System.put_env("KAFKA_BROKER_PORT", "9092")
