#!/bin/bash
#
# This script reverts the currently protected io7 platform back to non-secure mode
# all data are kept intact
sedOpt=
[ $(uname) = 'Darwin' ] && sedOpt=".bak"
sed -i $sedOpt 's/wss:/ws:/' ~/data/io7-management-web/public/runtime-config.js

docker compose -f ~/docker-compose.yml down

dir=$(pwd)/$(dirname $(echo $0))
cp ~/docker-compose.yml ~/docker-compose.yml.ssl
node $dir/modify-docker-compose.js ~/docker-compose.yml <<EOF
services.mqtt.ports: 8883:8883 -
services.mqtt.ports: 1883:1883
services.nodered.volumes: ./data/certs:/data/certs -
services.influxdb.environment: INFLUXD_TLS_CERT -
services.influxdb.environment: INFLUXD_TLS_KEY -
services.influxdb.volumes: ./data/certs:/data/certs -
services.io7api.environment: MQTT_PORT -
services.io7api.environment: MQTT_CONN -
services.io7api.environment: SSL_CERT -
services.io7api.environment: SSL_KEY -
services.io7api.environment: MQTT_SSL_CERT=./cer -
services.io7api.volumes: ./data/certs:/app/certs -
services.io7web.volumes: ./data/certs:/home/node/app/certs -
services.grafana.environment: GF_SERVER_PROTOCOL -
services.grafana.environment: GF_SERVER_CERT_FILE -
services.grafana.environment: GF_SERVER_CERT_KEY -
EOF

cp $dir/../data/nodered/settings.js ~/data/nodered/settings.js
sudo cp $dir/../data/mosquitto/config/mosquitto.conf ~/data/mosquitto/config/mosquitto.conf

for d in `find ~/data -type d -name certs`; do sudo rm -rf $d/*; done
docker compose -f ~/docker-compose.yml up -d
