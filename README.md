# KafkaexLagExporter

This project will collect Kafka consumer lag and provide them via Prometheus.

## Start

```bash
docker run -ti --net="host" -e KAFKA_BROKERS=localhost:9093,localhost:9094,localhost:9095 lechindianer/kafkaex_lag_exporter:0.1
```

Now you can check the exposed metrics at [localhost:4000](localhost:4000).

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

Kowl is served at [localhost:8080](localhost:8080).

### Tests

```bash
MIX_ENV=test mix test --no-test 

# Don't forget to check credo for code violations:
mix credo
```

## Links

Source is on [Gitlab](https://gitlab.com/lechindianer/kafkaex-lag-exporter).
