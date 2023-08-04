#!/bin/bash
#
# This script reverts the currently protected io7 platform back to non-secure mode
# all data are kept intact
sedOpt=
[ $(uname) = 'Darwin' ] && sedOpt=".bak"
sed -i $sedOpt 's/wss:/ws:/' ~/data/io7-management-web/public/runtime-config.js

docker-compose -f ~/docker-compose.yml down

dir=$(pwd)/$(dirname $(echo $0))
cp $dir/../docker-compose.yml.prod ~/docker-compose.yml

cp ~/data/nodered/settings.js.nossl ~/data/nodered/settings.js
cp ~/data/mosquitto/config/mosquitto.conf.nossl ~/data/mosquitto/config/mosquitto.conf

for d in `find ~/data -type d -name certs`; do rm -rf $d/*; done
docker-compose -f ~/docker-compose.yml up -d