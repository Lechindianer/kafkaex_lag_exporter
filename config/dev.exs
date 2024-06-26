import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :kafkaex_lag_exporter, KafkaexLagExporterWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "lttLR5uTgFy2WzfJLo+uXLWnogim+X/ZoJ9aqOWlJew3TsFm8dYXvsk1OpYUy2F8",
  watchers: []

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :brod,
  clients: [
    client1: [
      # non ssl
      endpoints: [redpanda: 29092],
      # endpoints: [localhost: 9093], # ssl
      # for safety, default true
      allow_topic_auto_creation: false,
      # get_metadata_timeout_seconds: 5, # default 5
      # max_metadata_sock_retry: 2, # seems obsolete
      max_metadata_sock_retry: 5,
      # query_api_versions: false, # default true, set false for Kafka < 0.10
      # reconnect_cool_down_seconds: 1, # default 1
      # default 5
      restart_delay_seconds: 10
    ]
  ]
