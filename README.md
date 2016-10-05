# Kafka in Docker

This repository provides everything you need to run Kafka 0.10.0.0 in Docker.

Based on [spotify/docker-kafka](https://github.com/spotify/docker-kafka) with some additions from other branches.

## Why?

The main hurdle of running Kafka in Docker is that it depends on Zookeeper.
Compared to other Kafka docker images, this one runs both Zookeeper and Kafka
in the same container. This means:

* No dependency on an external Zookeeper host, or linking to another container
* Zookeeper and Kafka are configured to work together out of the box

## Environment variables

* `ADVERTISED_HOST`: the host name part of the `advertised.listeners` config. This will be advertised on ZooKeeper
* `ADVERTISED_PORT`: port for `advertised.listeners`
* `ADVERTISED_PROTO`: protocol to advertise. Defaults to `PLAINTEXT`
* `ZK_CHROOT`: Zookeeper chroot. Defaults to `/`
* Any variable prefixed with `KAFKA_` will be transformed to a config parameter name: e.g. `KAFKA_AUTO_CREATE_TOPICS_ENABLE=false` will set `auto.create.topic` to `false`

## Run

```bash
docker run -p 2181:2181 -p 9092:9092 --env ADVERTISED_HOST=$(docker-machine ip $(docker-machine active)) --env ADVERTISED_PORT=9092 orbat/kafka
```

```bash
export KAFKA=$(docker-machine ip $(docker-machine active)):9092
kafka-console-producer.sh --broker-list $KAFKA --topic test
```

```bash
export ZOOKEEPER=$(docker-machine ip $(docker-machine active)):2181
kafka-console-consumer.sh --zookeeper $ZOOKEEPER --topic test
```

## Public Builds

https://registry.hub.docker.com/u/orbat/kafka/

## Build from Source

    docker build -t orbat/kafka .

## Todo

* Not particularily optimized for startup time
