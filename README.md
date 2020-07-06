# docker-vernemq
Adjusted default vernemq container

## Volumes
* /vernemq/etc - Purpose: Holds all the config information of vernemq
* /vernemq/data - Purpose: Holds all MQTT data
* /vernemq/log - Purpose: Holds all logs
* /vernemq/ssl - Purpose: Holds all certificates and private keys for MQTT TLS, postgress, etc

## Run
```shell
docker run --name vernemq \
    -v volume-etc:/vernemq/etc \
    -d 11notes/vernemq:[tag]
```
## Defaults
* Modified redis.lua to specify mountpoint in redis with acl (you must add mountpoint:"name" to your JSON)

## Docker -u 10000:10000 (no root initiative)
As part to make containers more secure, this container will not run as root, but as uid:gid 10000:10000.

## Build with
* [Alpine Linux](https://alpinelinux.org/) - Alpine Linux
* [VerneMQ](https://vernemq.com/) - VerneMQ

## Tips

* Don't bind to ports < 1024 (requires root), use NAT
* [Permanent Storge with NFS/CIFS/...](https://github.com/11notes/alpine-docker-netshare) - Module to store permanent container data via NFS/CIFS/...