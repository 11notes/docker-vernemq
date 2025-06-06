# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_ROOT=/vernemq

  # :: FOREIGN IMAGES
  FROM 11notes/util AS util

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
  FROM alpine AS build

  COPY --from=util /usr/local/bin /usr/local/bin

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
      upx \
      build-base;

  RUN set -ex; \
    git clone https://github.com/vernemq/vernemq.git -b ${APP_VERSION};

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
    COPY --from=util /usr/local/bin /usr/local/bin
    COPY --from=build ${BUILD_ROOT}/_build/default/rel/vernemq/ ${APP_ROOT}
    COPY --chown=${APP_UID}:${APP_GID} ./rootfs /

# :: RUN
  USER root
  RUN set -ex; \
    apk --no-cache --update add \
      snappy \
      ncurses-libs \
      libstdc++; \
    ln -sf ${APP_ROOT}/data ${APP_ROOT}/var; \
    chmod +x -R /usr/local/bin; \
    chown -R ${APP_UID}:${APP_GID} \
      ${APP_ROOT}; \
    usermod -d ${APP_ROOT}/data $(getent passwd ${APP_UID} | cut -d: -f1);

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var"]

# :: HEALTH
  HEALTHCHECK --interval=5s --timeout=2s --start-interval=5s \
    CMD ["curl", "-kILs", "--fail", "-o", "/dev/null", "http://localhost:8080/health/listeners"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}