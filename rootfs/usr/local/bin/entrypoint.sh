#!/bin/ash
  if [ -z "${1}" ]; then
    siguser1_handler() {
      echo "stopped"
    }

    sigterm_handler() {
      ${APP_ROOT}/bin/vmq-admin cluster leave node=VerneMQ@${DOCKER_VERNEMQ_NODENAME} -k -i 5 -t 60 > /dev/null
      ${APP_ROOT}/bin/vmq-admin node stop > /dev/null
      kill -s TERM ${pid}
      exit 0
    }

    trap 'siguser1_handler' SIGUSR1
    trap 'sigterm_handler' SIGTERM

    cd ${APP_ROOT}

    if env | grep "DOCKER_VERNEMQ_NODENAME" -q; then
      sed -i.bak -r "s/-name VerneMQ@.+/-name VerneMQ@${DOCKER_VERNEMQ_NODENAME}/" ${APP_ROOT}/etc/vm.args
    fi

    if env | grep "DOCKER_VERNEMQ_DISTRIBUTED_COOKIE" -q; then
        sed -i.bak -r "s/-setcookie .+/-setcookie ${DOCKER_VERNEMQ_DISTRIBUTED_COOKIE}/" ${APP_ROOT}/etc/vm.args
    fi

    if env | grep "DOCKER_VERNEMQ_DISCOVERY_NODE" -q; then
        sed -i.bak -r "s/-eval.+/-eval \"vmq_server_cmd:node_join('VerneMQ@$DOCKER_VERNEMQ_DISCOVERY_NODE')\"/" ${APP_ROOT}/etc/vm.args
    else
        sed -i.bak -r '/^-eval/d' ${APP_ROOT}/etc/vm.args
    fi

    ${APP_ROOT}/bin/vernemq config generate &> /dev/null

    set -- "${APP_ROOT}/bin/vernemq" \
      console \
      -noshell \
      -noinput
      
    eleven log start
  fi

  exec "$@"