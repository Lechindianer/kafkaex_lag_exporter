defmodule KafkaexLagExporter.KafkaWrapper.Behaviour do
  @moduledoc false

  @type client() :: :brod.client()
  @type endpoint() :: :brod.endpoint()
  @type conn_config() :: :brod.conn_config()
  @type group_id() :: :kpro.group_id()
  @type kpro_struct() :: :kpro.struct()
  @type topic() :: :kpro.topic()
  @type partition() :: :kpro.partition()
  @type offset_time() :: :kpro.msg_ts() | :earliest | :latest
  @type kpro_config() :: [{atom, term()}] | :kpro.conn_config()
  @type offset() :: :kpro.offset()
  @type cg() :: any()

  @callback fetch_committed_offsets(list(endpoint()), conn_config(), group_id()) ::
              {:ok, list(kpro_struct())} | {:error, any()}

  @callback get_partitions_count(client(), topic()) :: {:ok, pos_integer} | {:error, any()}

  @callback resolve_offset(list([endpoint()]), topic(), partition(), offset_time(), kpro_config()) ::
              {:ok, offset()} | {:error, any()}

  @callback list_all_groups(list(endpoint()), conn_config()) ::
              list({endpoint(), list(cg())} | {:error, any()})

  @callback describe_groups(endpoint(), conn_config(), list(group_id())) ::
              {:ok, list(kpro_struct())} | {:error, any()}

  def fetch_committed_offsets(endpoints, sock_opts, consumer_group),
    do: impl().fetch_committed_offsets(endpoints, sock_opts, consumer_group)

  def get_partitions_count(client, topic), do: impl().get_partitions_count(client, topic)

  def resolve_offset(endpoints, topic, i, type, sock_opts),
    do: impl().resolve_offset(endpoints, topic, i, type, sock_opts)

  def list_all_groups(endpoints, sock_opts),
    do: impl().list_all_groups(endpoints, sock_opts)

  def describe_groups(endpoint, sock_opts, consumer_group_names),
    do: impl().describe_groups(endpoint, sock_opts, consumer_group_names)

  defp impl, do: Application.get_env(:kafkaex_lag_exporter, :kafka_wrapper, :brod)
end
