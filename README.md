# KafkaExLagExporter

This project will collect Kafka consumer lag and provide them via Prometheus.

## Metrics

[Prometheus](https://prometheus.io/) is a standard way to represent metrics in a modern cross-platform manner. 
KafkaExLagExporter exposes several metrics as an HTTP endpoint that can be readily scraped by Prometheus.

**`kafka_consumergroup_group_topic_sum_lag`**

Labels: `cluster_name, group, topic, consumer_id, member_host`

The sum of the difference between the last produced offset and the last consumed offset of all partitions in this
topic for this group.

**`kafka_consumergroup_group_lag`**

Labels: `cluster_name, group, partition, topic, member_host, consumer_id`

The difference between the last produced offset and the last consumed offset for this partition in this topic
partition for this group.

## Start

```bash
docker run -ti --net="host" -e KAFKA_BROKERS=localhost:9093,localhost:9094,localhost:9095 -p 4000:4000 \
  lechindianer/kafkaex_lag_exporter:0.2.0
```

Now you can check the exposed metrics at [http://localhost:4000](http://localhost:4000).

## Developing

To start the project locally:

```bash
KAFKA_BROKERS="localhost:9092" iex -S mix 
```

There is also a docker-compose file included which will start Kafka, serve Kowl (Web UI for Kafka) and start
KafkaexLagExporter:

```bash 
docker-compose up --build
```

Kowl is served at [http://localhost:8080](http://localhost:8080).

### Tests

```bash
MIX_ENV=test mix test --no-start
```

###  Code style

Don't forget to check [credo](https://hexdocs.pm/credo/overview.html) for code violations:

```bash
mix credo
```

This project also leverages the use of typespecs in order to provide static code checking:

```bash
mix dialyzer
```

## Links

Source is on [Gitlab](https://gitlab.com/lechindianer/kafkaex-lag-exporter).

The initial project [Kafka Lag Exporter](https://github.com/seglo/kafka-lag-exporter) was a huge inspiration for me
creating my first real Elixir project. Thank you!
