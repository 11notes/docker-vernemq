# :: Header
    FROM alpine:3.14.1
    ENV VERNEMQ_VERSION="1.12.1"


# :: Run
    USER root

    # :: prepare
        ENV PATH="/vernemq/bin:$PATH"
        RUN apk --update --no-cache add \
                ncurses-libs \
                openssl \
                libstdc++ \
                jq \
                curl \
                bash \
                snappy-dev \
            && addgroup --gid 1000 vernemq \
            && adduser --uid 1000 -H -D -G vernemq -h /vernemq vernemq \
            && install -d -o vernemq -g vernemq /vernemq \
            && mkdir -p /vernemq/ssl/mqtt

    # :: install
        WORKDIR /vernemq

        ADD https://github.com/vernemq/vernemq/releases/download/$VERNEMQ_VERSION/vernemq-$VERNEMQ_VERSION.alpine.tar.gz /tmp

        RUN tar -xzvf /tmp/vernemq-$VERNEMQ_VERSION.alpine.tar.gz \
            && rm /tmp/vernemq-$VERNEMQ_VERSION.alpine.tar.gz \
            && ln -s /vernemq/etc /etc/vernemq \
            && ln -s /vernemq/data /var/lib/vernemq \
            && ln -s /vernemq/log /var/log/vernemq

    # :: copy root filesystem changes
        COPY ./rootfs /    
        COPY ./favicon.ico /vernemq/lib/vmq_server-$VERNEMQ_VERSION/priv/static

    # :: docker -u 1000:1000 (no root initiative)
        RUN chown -R vernemq:vernemq \
            /vernemq \
            /etc/vernemq \
            /var/lib/vernemq \
            /var/log/vernemq


# :: Volumes
    VOLUME ["/vernemq/data", "/vernemq/log", "/vernemq/etc", "/vernemq/ssl"]


# :: Monitor
    HEALTHCHECK CMD vernemq ping | grep -q pong


# :: Start
    RUN chmod +x /usr/local/bin/entrypoint.sh
    USER vernemq
    ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]