${{ content_synopsis }} Run one of the best and most modern MQTT brokers that exists, secured by default. It comes with a changed Redis authentication backend to write unauthenticated clients to the Redis DB for 15 minutes and allows multi-tenancy by using a mountpoint in the form of a FQDN.

${{ content_uvp }} Good question! All the other images on the market that do exactly the same don’t do or offer these options:

${{ github:> [!IMPORTANT] }}
${{ github:> }}* This image runs as 1000:1000 by default, most other images run everything as root
${{ github:> }}* This image is created via a secure, pinned CI/CD process and immune to upstream attacks, most other images have upstream dependencies that can be exploited
${{ github:> }}* This image contains a proper health check that verifies the app is actually working, most other images have either no health check or only check if a port is open or ping works
${{ github:> }}* This image works as read-only, most other images need to write files to the image filesystem
${{ github:> }}* This image is a lot smaller than most other images

If you value security, simplicity and the ability to interact with the maintainer and developer of an image. Using my images is a great start in that direction.

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
${{ github:> }}* The compose example has two additional containers for demo purposes, please create your own compose and do not copy/paste blindly