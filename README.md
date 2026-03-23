![banner](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/banner/README.png)

# VERNEMQ
![size](https://img.shields.io/badge/image_size-152MB-green?color=%2338ad2d)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![pulls](https://img.shields.io/docker/pulls/11notes/vernemq?color=2b75d6)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)[<img src="https://img.shields.io/github/issues/11notes/docker-vernemq?color=7842f5">](https://github.com/11notes/docker-vernemq/issues)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

Run VerneMQ rootless and secure by default!

# INTRODUCTION 📢

[VerneMQ](https://github.com/vernemq/vernemq) (created by [vernemq](https://github.com/vernemq/)) is a high-performance, distributed MQTT message broker. It scales horizontally and vertically on commodity hardware to support a high number of concurrent publishers and consumers while maintaining low latency and fault tolerance. VerneMQ is the reliable message hub for your IoT platform or smart products.

![STATUS](https://github.com/11notes/docker-vernemq/blob/master/img/status.png?raw=true)

# SYNOPSIS 📖
**What can I do with this?** Run one of the best and most modern MQTT brokers that exists, secured by default. It comes with a changed Redis authentication backend to write unauthenticated clients to the Redis DB for 15 minutes and allows multi-tenancy by using a mountpoint in the form of a FQDN.

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image is auto updated to the latest version via CI/CD
>* ... this image supports 32bit architecture
>* ... this image has a health check
>* ... this image runs read-only
>* ... this image is automatically scanned for CVEs before and after publishing
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | **size on disk** | **init default as** | **[distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)** | supported architectures
| ---: | ---: | :---: | :---: | :---: |
| 11notes/vernemq | 152MB | 1000:1000 | ❌ | amd64, arm64, armv7 |

# VOLUMES 📁
* **/vernemq/etc** - Directory of your configs
* **/vernemq/var** - Directory of your LevelDB and retained messages
* **/vernemq/ssl** - Directory of your SSL certificates

# COMPOSE ✂️
```yaml
name: "mqtts"

x-lockdown: &lockdown
  # prevents write access to the image itself
  read_only: true
  # prevents any process within the container to gain more privileges
  security_opt:
    - "no-new-privileges=true"

services:
  redis:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-redis
    image: "11notes/redis:8.2.2"
    <<: *lockdown
    environment:
      REDIS_PASSWORD: "${REDIS_PASSWORD}"
      TZ: "Europe/Zurich"
    networks:
      backend:
    volumes:
      - "redis.etc:/redis/etc"
      - "redis.var:/redis/var"
    tmpfs:
      - "/run:uid=1000,gid=1000"
    restart: "always"

  cli:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-redis
    depends_on:
      redis:
        condition: "service_healthy"
        restart: true
    image: "11notes/redis:8.2.2"
    <<: *lockdown
    environment:
      REDIS_HOST: "redis"
      REDIS_PASSWORD: "${REDIS_PASSWORD}"
      TZ: "Europe/Zurich"
    entrypoint: ["/usr/local/bin/redis", "--cmd"]
    command: 
      - SET client:mqttui@domain.com:mqttui {"mountpoint":"domain.com","passhash":"$2a$12$NZTnKE8a5e8/ey9Li6xwSeF92I0j1Us96jMl2zCESRlapx88u6Wxq","subscribe_acl":[{"pattern":"#"}],"publish_acl":[{"allowed_retain":true,"pattern":"#"}]} NX
    networks:
      backend:

  vernemq:
    depends_on:
      redis:
        condition: "service_healthy"
        restart: true
    image: "11notes/vernemq:2.1.1"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
    ports:
      - "3000:3000/tcp"
      - "8883:8883/tcp"
    networks:
      frontend:
      backend:
    volumes:
      - "vernemq.etc:/vernemq/etc"
      - "vernemq.var:/vernemq/var"

  # ╔═════════════════════════════════════════════════════╗
  # ║     DEMO CONTAINER - DO NOT USE IN PRODUCTION!      ║
  # ╚═════════════════════════════════════════════════════╝
  # used to give an UI for the Redis database

  redis-insight:
    depends_on:
      redis:
        condition: "service_healthy"
        restart: true
    image: "redis/redisinsight"
    environment:
      RI_REDIS_HOST0: "redis"
      RI_REDIS_PASSWORD0: "${REDIS_PASSWORD}"
      TZ: "Europe/Zurich"
    ports:
      - "3010:5540/tcp"
    networks:
      backend:
      frontend:

  # ╔═════════════════════════════════════════════════════╗
  # ║     DEMO CONTAINER - DO NOT USE IN PRODUCTION!      ║
  # ╚═════════════════════════════════════════════════════╝
  # web UI to visualize the MQTT messages sent

  mqtt-web-client:
    depends_on:
      vernemq:
        condition: "service_healthy"
        restart: true
    image: "terdia07/mqttui"
    entrypoint: ["/bin/sh","-c"]
    command:
      - |
        sed -i 's/mqttui_{os.getpid()}/{os.getenv('\''MQTT_CLIENT_ID'\'')}/' ./app.py
        exec gunicorn --worker-class eventlet -w 1 -b "0.0.0.0:5000" app:app
    environment:
      TZ: Europe/Zurich
      MQTT_BROKER: vernemq
      MQTT_PORT: 1883
      MQTT_USERNAME: mqttui@domain.com
      MQTT_PASSWORD: vernemq
      MQTT_CLIENT_ID: mqttui
    ports:
      - "3020:5000/tcp"
    networks:
      frontend:
      backend:
    restart: always

volumes:
  vernemq.etc:
  vernemq.var:
  redis.etc:
  redis.var:
  redis-insight.var:

networks:
  frontend:
  backend:
    internal: true
```
To find out how you can change the default UID/GID of this container image, consult the [RTFM](https://github.com/11notes/RTFM/blob/main/linux/container/image/11notes/how-to.changeUIDGID.md#change-uidgid-the-correct-way).

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /vernemq | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [2.1.1](https://hub.docker.com/r/11notes/vernemq/tags?name=2.1.1)
* [2.1.1-unraid](https://hub.docker.com/r/11notes/vernemq/tags?name=2.1.1-unraid)
* [2.1.1-nobody](https://hub.docker.com/r/11notes/vernemq/tags?name=2.1.1-nobody)

### There is no latest tag, what am I supposed to do about updates?
It is my opinion that the ```:latest``` tag is a bad habbit and should not be used at all. Many developers introduce **breaking changes** in new releases. This would messed up everything for people who use ```:latest```. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:2.1.1``` you can use ```:2``` or ```:2.1```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version. Which in theory should not introduce breaking changes.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/vernemq:2.1.1
docker pull ghcr.io/11notes/vernemq:2.1.1
docker pull quay.io/11notes/vernemq:2.1.1
```

# UNRAID VERSION 🟠
This image supports unraid by default. Simply add **-unraid** to any tag and the image will run as 99:100 instead of 1000:1000.

# NOBODY VERSION 👻
This image supports nobody by default. Simply add **-nobody** to any tag and the image will run as 65534:65534 instead of 1000:1000.

# SOURCE 💾
* [11notes/vernemq](https://github.com/11notes/docker-vernemq)

# PARENT IMAGE 🏛️
* [11notes/alpine:stable](https://hub.docker.com/r/11notes/alpine)

# BUILT WITH 🧰
* [vernemq](https://github.com/vernemq/vernemq)
* [11notes/util](https://github.com/11notes/docker-util)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services
>* Do not use MQTT without SSL (MQTT**S**)!
>* Use the ```subscribe_acl``` and ```publish_acl``` to restrict your MQTTS clients to certain topics and do not allow everything by default

# CAUTION ⚠️
> [!CAUTION]
>* This image is shipped with default SSL certificates that were generated during the container build process. Please provide your own SSL certificates
>* The compose example has a default Redis ACL for the client ```mqttui@domain.com```, please create your own compose and do not copy/paste blindly

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-vernemq/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-vernemq/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-vernemq/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 12.01.2026, 22:12:57 (CET)*