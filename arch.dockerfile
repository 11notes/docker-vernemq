# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# :: GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_GO_VERSION=0

# :: APP
  ARG BUILD_ROOT=/vernemq

# :: FOREIGN IMAGES
  FROM 11notes/util AS util
  FROM 11notes/util:bin AS util-bin
  FROM 11notes/distroless:localhealth AS distroless-localhealth

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: ENTRYPOINT
  FROM 11notes/go:${APP_GO_VERSION} AS entrypoint
  ARG APP_GO_VERSION
  COPY --from=util-bin / /
  COPY ./build/go/entrypoint /go/entrypoint
  RUN set -eux; \
    eleven go build-entrypoint;


# :: VERNEMQ
  FROM alpine AS build

  COPY --from=util-bin / /

  ARG TARGETPLATFORM \
      TARGETOS \
      TARGETARCH \
      TARGETVARIANT \
      APP_VERSION \
      BUILD_ROOT

  RUN set -ex; \
    apk --update --no-cache add \
      git \
      make \
      cmake \
      gcc \
      musl-dev \
      linux-headers \
      bsd-compat-headers \
      erlang-dev \
      snappy-dev \
      openssl \
      openssl-dev \
      libstdc++-dev  \
      ncurses-libs \
      build-base;

  RUN set -ex; \
    eleven git clone vernemq/vernemq.git ${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    make rel -s -j $(nproc) || echo "leveldb pull error, retry"; \
    make rel -s -j $(nproc);

  RUN set -ex; \
    mkdir -p ${BUILD_ROOT}/_build/default/rel/vernemq/ssl; \
    openssl req -x509 -sha256 -days 3650 -nodes -subj "/C=XX/ST=XX/L=XX/O=XX/OU=XX/CN=VerneMQ" \
      -newkey rsa:4096 -keyout ${BUILD_ROOT}/_build/default/rel/vernemq/ssl/tls.key \
      -out ${BUILD_ROOT}/_build/default/rel/vernemq/ssl/tls.crt; \
    cp ${BUILD_ROOT}/_build/default/rel/vernemq/ssl/tls.crt ${BUILD_ROOT}/_build/default/rel/vernemq/ssl/ca.crt;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: HEADER
  FROM 11notes/alpine:stable

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE \
        BUILD_ROOT

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: app specific environment
    ENV DOCKER_VERNEMQ_ACCEPT_EULA="yes" \
        REDIS_HOST="redis" \
        REDIS_PORT=6379 \
        REDIS_PASSWORD="vernemq"

  # :: multi-stage
    COPY --from=util / /
    COPY --from=distroless-localhealth / /
    COPY --from=entrypoint /distroless/ /
    COPY --from=build ${BUILD_ROOT}/_build/default/rel/vernemq/ /opt/vernemq
    COPY --chown=${APP_UID}:${APP_GID} ./rootfs /

# :: RUN
  USER root
  RUN set -ex; \
    mkdir -p ${APP_ROOT}/etc; \
    mkdir -p ${APP_ROOT}/var; \
    apk --no-cache --update --virtual .tmp add \
      cmd:usermod; \
    apk --no-cache --update add \
      snappy \
      ncurses-libs; \
    rm -rf /opt/vernemq/data; \
    rm -rf /opt/vernemq/etc; \
    ln -sf ${APP_ROOT}/var /opt/vernemq/data; \
    ln -sf ${APP_ROOT}/etc /opt/vernemq/etc; \
    chmod +x -R /usr/local/bin; \
    chown -R ${APP_UID}:${APP_GID} \
      /opt/vernemq \
      ${APP_ROOT}; \
    usermod -d /opt/vernemq/data $(getent passwd ${APP_UID} | cut -d: -f1); \
    apk del --no-network .tmp;

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var"]

# :: HEALTH
  HEALTHCHECK --interval=5s --timeout=2s --start-interval=5s \
    CMD ["/usr/local/bin/localhealth", "http://127.0.0.1:8080/health/listeners", "-I"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/entrypoint"]