![banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# VERNEMQ
![size](https://img.shields.io/docker/image-size/11notes/vernemq/2.1.0?color=0eb305)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![version](https://img.shields.io/docker/v/11notes/vernemq/2.1.0?color=eb7a09)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![pulls](https://img.shields.io/docker/pulls/11notes/vernemq?color=2b75d6)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)[<img src="https://img.shields.io/github/issues/11notes/docker-VERNEMQ?color=7842f5">](https://github.com/11notes/docker-VERNEMQ/issues)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

Run VerneMQ rootless and secure by default!

# SYNOPSIS 📖
**What can I do with this?** Run one of the best and most modern MQTT brokers that exists, secured by default. It comes with a changed Redis authentication backend to write unauthenticated clients to the Redis DB for 15 minutes and allows multi-tenancy by using a mountpoint in the form of a FQDN.

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! All the other images on the market that do exactly the same don’t do or offer these options:

> [!IMPORTANT]
>* This image runs as 1000:1000 by default, most other images run everything as root
>* This image is created via a secure, pinned CI/CD process and immune to upstream attacks, most other images have upstream dependencies that can be exploited
>* This image contains a proper health check that verifies the app is actually working, most other images have either no health check or only check if a port is open or ping works
>* This image works as read-only, most other images need to write files to the image filesystem
>* This image is a lot smaller than most other images

If you value security, simplicity and the ability to interact with the maintainer and developer of an image. Using my images is a great start in that direction.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.



# VOLUMES 📁
* **/vernemq/etc** - Directory of your configs
* **/vernemq/var** - Directory of your LevelDB and retained messages
* **/vernemq/ssl** - Directory of your SSL certificates

# COMPOSE ✂️
```yaml
name: "mqtt"
services:
  redis:
    image: "11notes/redis:7.4.2"
    environment:
      REDIS_PASSWORD: ${REDIS_PASSWORD}
      TZ: "Europe/Zurich"
    command:
      - SET client:mqttui@domain.com:mqttui {"mountpoint":"domain.com","passhash":"$2a$12$NZTnKE8a5e8/ey9Li6xwSeF92I0j1Us96jMl2zCESRlapx88u6Wxq","subscribe_acl":[{"pattern":"#"}],"publish_acl":[{"allowed_retain":true,"pattern":"#"}]} NX
    volumes:
      - "redis.etc:/redis/etc"
      - "redis.var:/redis/var"
    networks:
      backend:
    restart: always

  vernemq:
    depends_on:
      redis:
        condition: "service_healthy"
        restart: true
    image: "11notes/vernemq:2.1.0"
    read_only: true
    environment:
      TZ: "Europe/Zurich"
    ports:
      - "3000:3000/tcp"
      - "7883:7883/tcp"
      - "8883:8883/tcp"
    networks:
      frontend:
      backend:
    volumes:
      - "etc:/vernemq/etc"
      - "var:/vernemq/var"

  redis-insight:
    # demo container to have an UI for the Redis database
    depends_on:
      redis:
        condition: "service_healthy"
        restart: true
    image: "11notes/redis-insight:2.58.0"
    environment:
      TZ: Europe/Zurich
    ports:
      - "3010:5540/tcp"
    networks:
      frontend:
      backend:
    volumes:
      - "redis-insight.var:/redis-insight/var"
    restart: always

  mqtt-web-client:
    # demo container to access VerneMQ as an MQTT client via internal network
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
  etc:
  var:
  redis.etc:
  redis.var:
  redis-insight.var:

networks:
  frontend:
  backend:
    internal: true
```

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

* [2.1.0](https://hub.docker.com/r/11notes/vernemq/tags?name=2.1.0)

### There is no latest tag, what am I supposed to do about updates?
It is of my opinion that the ```:latest``` tag is super dangerous. Many times, I’ve introduced **breaking** changes to my images. This would have messed up everything for some people. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:2.1.0``` you can use ```:2``` or ```:2.1```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/vernemq:2.1.0
docker pull ghcr.io/11notes/vernemq:2.1.0
docker pull quay.io/11notes/vernemq:2.1.0
```

# SOURCE 💾
* [11notes/vernemq](https://github.com/11notes/docker-VERNEMQ)

# PARENT IMAGE 🏛️
* [${{ json_readme_parent_image }}](${{ json_readme_parent_url }})

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
>* The compose example has two additional containers for demo purposes, please create your own compose and do not copy/paste blindly

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-vernemq/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-vernemq/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-vernemq/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 06.06.2025, 11:21:51 (CET)*