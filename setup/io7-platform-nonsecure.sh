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
cp $dir/../data/nodered/settings.js ~/data/nodered/settings.js
sudo cp $dir/../data/mosquitto/config/mosquitto.conf ~/data/mosquitto/config/mosquitto.conf

for d in `find ~/data -type d -name certs`; do sudo rm -rf $d/*; done
docker-compose -f ~/docker-compose.yml up -d
