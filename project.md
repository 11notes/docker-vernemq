${{ image: status.png }}

${{ content_synopsis }} Run one of the best and most modern MQTT brokers that exists, secured by default. It comes with a changed Redis authentication backend to write unauthenticated clients to the Redis DB for 15 minutes and allows multi-tenancy by using a mountpoint in the form of a FQDN.

${{ content_uvp }} Good question! Because ...

${{ github:> [!IMPORTANT] }}
${{ github:> }}* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
${{ github:> }}* ... this image is auto updated to the latest version via CI/CD
${{ github:> }}* ... this image supports 32bit architecture
${{ github:> }}* ... this image has a health check
${{ github:> }}* ... this image runs read-only
${{ github:> }}* ... this image is automatically scanned for CVEs before and after publishing
${{ github:> }}* ... this image is created via a secure and pinned CI/CD process
${{ github:> }}* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

${{ content_comparison }}

${{ title_volumes }}
* **${{ json_root }}/etc** - Directory of your configs
* **${{ json_root }}/var** - Directory of your LevelDB and retained messages
* **${{ json_root }}/ssl** - Directory of your SSL certificates

${{ content_compose }}

${{ content_defaults }}

${{ content_environment }}

${{ content_source }}

${{ content_parent }}

${{ content_built }}

${{ content_tips }}
${{ github:> }}* Do not use MQTT without SSL (MQTT**S**)!
${{ github:> }}* Use the ```subscribe_acl``` and ```publish_acl``` to restrict your MQTTS clients to certain topics and do not allow everything by default

${{ title_caution }}
${{ github:> [!CAUTION] }}
${{ github:> }}* This image is shipped with default SSL certificates that were generated during the container build process. Please provide your own SSL certificates
${{ github:> }}* The compose example has a default Redis ACL for the client ```mqttui@domain.com```, please create your own compose and do not copy/paste blindly