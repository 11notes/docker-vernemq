# docker-vernemq
Adjusted default vernemq container with modified uid:gid and modified start settings

## Volumes
* /vernemq/etc - Purpose: Holds all the config information of vernemq
* /vernemq/data - Purpose: Holds all MQTT data (levelDB)
* /vernemq/log - Purpose: Holds all logs
* /vernemq/ssl - Purpose: Holds all certificates and private keys for MQTT TLS, postgress, etc

## Run
```shell
docker run --name vernemq \
    -v volume-etc:/vernemq/etc \
    -v volume-data:/vernemq/data \
    -v volume-log:/vernemq/log \
    -v volume-ssl:/vernemq/ssl \
    -d 11notes/vernemq:[tag]
```
## Defaults
* Modified redis.lua to specify mountpoint in redis with acl (you must add mountpoint:"name" to your JSON)

## Examples
* Redis topic ACL with mountpoint (topic tree)
```shell
redis-cli
    SET "client:USERNAME:CLIENT_ID" "{\"mountpoint\":\"MOUNTPOINT\",\"passhash\":\"BCRYPT2APASSHASH\",\"subscribe_acl\":[{\"pattern\":\"my/custom/topic/acl/#\"}],\"publish_acl\":[{\"pattern\":\"my/custom/+/acl/#\"}]}"
```
* Cluster docker environment variables and sample vernemq.conf
```shell
docker run --name vernemq \
    -v volume-etc:/vernemq/etc \
    -v volume-data:/vernemq/data \
    -v volume-log:/vernemq/log \
    -v volume-ssl:/vernemq/ssl \
    -e DOCKER_VERNEMQ_NODENAME="IP_OF_CONTAINER" \
    -e DOCKER_VERNEMQ_DISCOVERY_NODE="IP_OF_CLUSTER_MASTER" \
    -e DOCKER_VERNEMQ_DISTRIBUTED_COOKIE="SECRET_CLUSTER_KEY_DONT_TELL_OTHER_CLUSTERS" \
        -d 11notes/vernemq:[tag]
```
```shell
erlang.distribution.port_range.minimum = 6000
erlang.distribution.port_range.maximum = 7999
listener.vmq.clustering = IP_OF_CONTAINER:44053 # do not use 0.0.0.0
```

## Docker -u 1000:1000 (no root initiative)
As part to make containers more secure, this container will not run as root, but as uid:gid 1000:1000.

## Build with
* [Alpine Linux](https://alpinelinux.org/) - Alpine Linux
* [VerneMQ](https://vernemq.com/) - VerneMQ

## Tips

* Don't bind to ports < 1024 (requires root), use NAT
* [Permanent Storge with NFS/CIFS/...](https://github.com/11notes/alpine-docker-netshare) - Module to store permanent container data via NFS/CIFS/...