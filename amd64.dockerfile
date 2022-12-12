# :: Header
    FROM alpine:latest
    ENV VERNEMQ_VERSION="1.12.6.2"

# :: Run
    USER root

    # :: prepare
        RUN set -ex; \
            apk --update --no-cache add \
                ncurses-libs \
                openssl \
                libstdc++ \
                jq \
                bash \
                curl \
                snappy-dev \
                libcrypto1.1; \
            addgroup --gid 1000 vernemq; \
            adduser --uid 1000 -H -D -G vernemq -h /vernemq vernemq; \
            install -d -o vernemq -g vernemq /vernemq; \
            mkdir -p /vernemq/etc; \
            mkdir -p /vernemq/var; \
            mkdir -p /vernemq/log;

    # :: install
        WORKDIR /vernemq

        ADD https://github.com/vernemq/vernemq/releases/download/${VERNEMQ_VERSION}/vernemq-${VERNEMQ_VERSION}.alpine.tar.gz /tmp
        ENV PATH="/vernemq/bin:$PATH"

        RUN set -ex; \
            tar -xzvf /tmp/vernemq-${VERNEMQ_VERSION}.alpine.tar.gz; \
            rm /tmp/vernemq-${VERNEMQ_VERSION}.alpine.tar.gz; \
            ln -s /vernemq/etc /etc/vernemq; \
            ln -s /vernemq/data /var/lib/vernemq; \
            ln -s /vernemq/log /var/log/vernemq;

    # :: copy root filesystem changes
        COPY ./rootfs /

    # :: docker -u 1000:1000 (no root initiative)
        RUN chown -R vernemq:vernemq \
            /vernemq;


# :: Volumes
    VOLUME ["/vernemq/etc", "/vernemq/ssl"]


# :: Monitor
    HEALTHCHECK CMD vernemq ping | grep -q pong


# :: Start
    RUN chmod +x /usr/local/bin/entrypoint.sh
    USER vernemq
    ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]