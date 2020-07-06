# :: Header
    FROM alpine:3.12
    ENV VERNEMQ_VERSION="1.10.3"

# :: Run
    USER root

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

    WORKDIR /vernemq

    ADD https://github.com/vernemq/vernemq/releases/download/$VERNEMQ_VERSION/vernemq-$VERNEMQ_VERSION.alpine.tar.gz /tmp

    RUN tar -xzvf /tmp/vernemq-$VERNEMQ_VERSION.alpine.tar.gz \
        && rm /tmp/vernemq-$VERNEMQ_VERSION.alpine.tar.gz \
        && ln -s /vernemq/etc /etc/vernemq \
        && ln -s /vernemq/data /var/lib/vernemq \
        && ln -s /vernemq/log /var/log/vernemq

    COPY ./source/share /vernemq/share
    COPY ./source/etc /vernemq/etc
    COPY ./source/entrypoint.sh /usr/local/bin/entrypoint.sh
    RUN chmod +x /usr/local/bin/entrypoint.sh

    # :: docker -u 1000:1000 (no root initiative)
        RUN chown -R vernemq:vernemq \
            /vernemq \
            /etc/vernemq \
            /var/lib/vernemq \
            /var/log/vernemq

# :: Volumes
    VOLUME ["/vernemq/data", "/vernemq/log", "/vernemq/etc"]

# :: Monitor
    HEALTHCHECK CMD vernemq ping | grep -q pong

# :: Start
    USER vernemq
    ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]