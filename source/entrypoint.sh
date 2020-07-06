#!/usr/bin/env bash

IP_ADDRESS=$(ip -4 addr show ${DOCKER_NET_INTERFACE:-eth0} | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sed -e "s/^[[:space:]]*//" | head -n 1)
IP_ADDRESS=${DOCKER_IP_ADDRESS:-${IP_ADDRESS}}

# Ensure the Erlang node name is set correctly
if env | grep "DOCKER_VERNEMQ_NODENAME" -q; then
    sed -i.bak -r "s/-name VerneMQ@.+/-name VerneMQ@${DOCKER_VERNEMQ_NODENAME}/" /vernemq/etc/vm.args
fi

if env | grep "DOCKER_VERNEMQ_DISTRIBUTED_COOKIE" -q; then
    sed -i.bak -r "s/-setcookie .+/-setcookie ${DOCKER_VERNEMQ_DISTRIBUTED_COOKIE}/" /vernemq/etc/vm.args
fi

if env | grep "DOCKER_VERNEMQ_DISCOVERY_NODE" -q; then
    discovery_node=$DOCKER_VERNEMQ_DISCOVERY_NODE
    echo $'\n-eval "vmq_server_cmd:node_join('VerneMQ@${discovery_node}')"' >> /vernemq/etc/vm.args
fi

# Check configuration file
/vernemq/bin/vernemq config generate 2>&1 > /dev/null | tee /tmp/config.out | grep error

if [ $? -ne 1 ]; then
    echo "configuration error, exit"
    echo "$(cat /tmp/config.out)"
    exit $?
fi

pid=0

# SIGUSR1-handler
siguser1_handler() {
    echo "stopped"
}

# SIGTERM-handler
sigterm_handler() {
    if [ $pid -ne 0 ]; then
        # this will stop the VerneMQ process, but first drain the node from all existing client sessions (-k)
        if [ -n "$VERNEMQ_KUBERNETES_HOSTNAME" ]; then
            terminating_node_name=VerneMQ@$VERNEMQ_KUBERNETES_HOSTNAME
        elif [ -n "$DOCKER_VERNEMQ_SWARM" ]; then
            terminating_node_name=VerneMQ@$(hostname -i)
        else
            terminating_node_name=VerneMQ@$IP_ADDRESS
        fi
        /vernemq/bin/vmq-admin cluster leave node=$terminating_node_name -k > /dev/null
        /vernemq/bin/vmq-admin node stop > /dev/null
        kill -s TERM ${pid}
        exit 0
    fi
}

# Setup OS signal handlers
trap 'siguser1_handler' SIGUSR1
trap 'sigterm_handler' SIGTERM

# Start VerneMQ
/vernemq/bin/vernemq console -noshell -noinput $@ &
pid=$!
wait $pid
