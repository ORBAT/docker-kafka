#!/bin/bash

# Optional ENV variables:
# * ADVERTISED_HOST: the external ip for the container, e.g. `docker-machine ip \`docker-machine active\``
# * ADVERTISED_PORT: the external port for Kafka, e.g. 9092
# * ADVERTISED_PROTO: protocol to advertise and listen. Defaults to PLAINTEXT
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
#
# Any variable prefixed with KAFKA will be transformed to name of parameter for example
# KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'false' will set auto.create.topic to false

ADVERTISED_PORT=${ADVERTISED_PORT:-9092}
ADVERTISED_PROTO=${PROTO:-PLAINTEXT}

# Set the external host and port
if [ ! -z "$ADVERTISED_HOST" ]; then
    echo "advertised host: ${ADVERTISED_PROTO}://${ADVERTISED_HOST}:${ADVERTISED_PORT}"
    sed -r -i "s/#(advertised.listeners)=(.*)/\1=${ADVERTISED_PROTO}:\/\/${ADVERTISED_HOST}:${ADVERTISED_PORT}/g" $KAFKA_HOME/config/server.properties
fi

# Set the zookeeper chroot
if [ ! -z "$ZK_CHROOT" ]; then
    # wait for zookeeper to start up
    until /usr/share/zookeeper/bin/zkServer.sh status; do
      sleep 0.1
    done

    # create the chroot node
    echo "create /$ZK_CHROOT \"\"" | /usr/share/zookeeper/bin/zkCli.sh || {
        echo "can't create chroot in zookeeper, exit"
        exit 1
    }

    # configure kafka
    sed -r -i "s/(zookeeper.connect)=(.*)/\1=localhost:2181\/$ZK_CHROOT/g" $KAFKA_HOME/config/server.properties
fi

### START LICENSED CODE ###
# The following is copied from https://github.com/wurstmeister/kafka-docker/blob/master/start-kafka.sh
# under ASL v2 license

for VAR in `env`
do
  if [[ $VAR =~ ^KAFKA_ && ! $VAR =~ ^KAFKA_HOME && ! $VAR =~ ^KAFKA_VERSION ]]; then
    kafka_name=`echo "$VAR" | sed -r "s/KAFKA_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
    env_var=`echo "$VAR" | sed -r "s/(.*)=.*/\1/g"`
    if egrep -q "(^|^#)$kafka_name=" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s@(^|^#)($kafka_name)=(.*)@\2=${!env_var}@g" $KAFKA_HOME/config/server.properties #note that no config values may contain an '@' char
    else
        echo "$kafka_name=${!env_var}" >> $KAFKA_HOME/config/server.properties
    fi
    echo "$kafka_name=$env_var (${!env_var})"
  fi
done

### END LICENSED CODE ###

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties