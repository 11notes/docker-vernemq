# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# :: GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_ROOT=/vernemq

# :: FOREIGN IMAGES
  FROM 11notes/util AS util
  FROM 11notes/util:bin AS util-bin
  FROM 11notes/distroless:localhealth AS distroless-localhealth

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
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
      -newkey rsa:4096 -keyout ${BUILD_ROOT}/_build/default/rel/vernemq/ssl/default.key \
      -out ${BUILD_ROOT}/_build/default/rel/vernemq/ssl/default.crt;


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
    ENV DOCKER_VERNEMQ_ACCEPT_EULA="yes"

  # :: multi-stage
    COPY --from=util / /
    COPY --from=distroless-localhealth / /
    COPY --from=build ${BUILD_ROOT}/_build/default/rel/vernemq/ ${APP_ROOT}
    COPY --chown=${APP_UID}:${APP_GID} ./rootfs /

# :: RUN
  USER root
  RUN set -ex; \
    apk --no-cache --update --virtual .tmp add \
      cmd:usermod; \
    apk --no-cache --update add \
      snappy \
      ncurses-libs; \
    ln -sf ${APP_ROOT}/data ${APP_ROOT}/var; \
    chmod +x -R /usr/local/bin; \
    chown -R ${APP_UID}:${APP_GID} \
      ${APP_ROOT}; \
    usermod -d ${APP_ROOT}/data $(getent passwd ${APP_UID} | cut -d: -f1); \
    apk del --no-network .tmp;

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var"]

# :: HEALTH
  HEALTHCHECK --interval=5s --timeout=2s --start-interval=5s \
    CMD ["/usr/local/bin/localhealth", "http://127.0.0.1:8080/health/listeners", "-I"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]