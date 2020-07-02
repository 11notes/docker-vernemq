# :: Header
    FROM vernemq/vernemq:1.10.3-alpine

# :: Run
    USER root

    RUN apk --update --no-cache add \
            shadow \
        && mkdir -p /vernemq/ssl/mqtt
        
    COPY ./source/share /vernemq/share

    # :: docker -u 1000:1000 (no root initiative)
        RUN APP_UID="$(id -u vernemq)" \
            && APP_GID="$(id -g vernemq)" \
            && find / -not -path "/proc/*" -user $APP_UID -exec chown -h -R 1000:1000 {} \;\
            && find / -not -path "/proc/*" -group $APP_GID -exec chown -h -R 1000:1000 {} \;
        RUN usermod -u 1000 vernemq \
            && groupmod -g 1000 vernemq \
            && chown -R 1000:1000 /vernemq

    USER vernemq