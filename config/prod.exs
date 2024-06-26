import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
# config :kafkaex_lag_exporter, KafkaexLagExporterWeb.Endpoint,
#  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :kafkaex_lag_exporter, KafkaexLagExporterWeb.Endpoint,
#       ...,
#       url: [host: "example.com", port: 443],
#       https: [
#         ...,
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your endpoint, ensuring
# no data is ever sent via http, always redirecting to https:
#
#     config :kafkaex_lag_exporter, KafkaexLagExporterWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

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
