#!/bin/ash

IP_ADDRESS=$(ip -4 addr show ${NET_INTERFACE} | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sed -e "s/^[[:space:]]*//" | head -n 1)
if env | grep "DOCKER_VERNEMQ_NODENAME" -q; then
    sed -i.bak -r "s/-name VerneMQ@.+/-name VerneMQ@${DOCKER_VERNEMQ_NODENAME}/" /vernemq/etc/vm.args
fi

if env | grep "DOCKER_VERNEMQ_DISTRIBUTED_COOKIE" -q; then
    sed -i.bak -r "s/-setcookie .+/-setcookie ${DOCKER_VERNEMQ_DISTRIBUTED_COOKIE}/" /vernemq/etc/vm.args
fi

if env | grep "DOCKER_VERNEMQ_DISCOVERY_NODE" -q; then
    sed -i.bak -r "s/-eval.+/-eval \"vmq_server_cmd:node_join('VerneMQ@$DOCKER_VERNEMQ_DISCOVERY_NODE')\"/" /vernemq/etc/vm.args
else
    sed -i.bak -r '/^-eval/d' /vernemq/etc/vm.args
fi

# SIGUSR1-handler
siguser1_handler() {
    echo "stopped"
}

# SIGTERM-handler
sigterm_handler() {
    /vernemq/bin/vmq-admin cluster leave node=VerneMQ@${DOCKER_VERNEMQ_NODENAME} -k -i 5 -t 60 > /dev/null
    /vernemq/bin/vmq-admin node stop > /dev/null
    kill -s TERM ${pid}
    exit 0
}

# Setup OS signal handlers
trap 'siguser1_handler' SIGUSR1
trap 'sigterm_handler' SIGTERM

/vernemq/bin/vernemq config generate

# Start VerneMQ
if [ -z "$1" ]; then
    set -- "vernemq" \
        console \
        -noshell \
        -noinput
fi

exec "$@"