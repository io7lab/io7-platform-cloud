#!/bin/bash
#
# This script reverts the currently protected io7 platform back to non-secure mode
# all data are kept intact
dir=$(pwd)/$(dirname $(echo $0))

sedOpt=
[ $(uname) = 'Darwin' ] && sedOpt=".bak"
sed -i $sedOpt 's/wss:/ws:/' ~/data/io7-management-web/public/runtime-config.js

if [ -z $NODE_PATH ] ; then
    export NODE_PATH=$(dirname $(which node))/../lib/node_modules
fi

cp ~/data/nodered/settings.js ~/data/nodered/settings.js.ssl
docker cp $dir/modify-nodered-settings.js nodered:/tmp
docker exec -i nodered /usr/local/bin/node /tmp/modify-nodered-settings.js /data/settings.js  << EOF
adminAuth: require('io7-nodered-auth/io7-authentication')({
   AUTH_SERVER_URL: 'http://io7api:2009/users/login'
}),
EOF
docker exec -i nodered /usr/local/bin/node /tmp/modify-nodered-settings.js /data/settings.js  << EOF
- https: {
EOF

docker compose -f ~/docker-compose.yml down

cp ~/docker-compose.yml ~/docker-compose.yml.ssl
node $dir/modify-docker-compose.js ~/docker-compose.yml <<EOF
- services.mqtt.ports: 8883:8883
services.mqtt.ports: 1883:1883
- services.nodered.volumes: ./data/certs:/data/certs
- services.influxdb.environment: INFLUXD_TLS_CERT
- services.influxdb.environment: INFLUXD_TLS_KEY
- services.influxdb.volumes: ./data/certs:/data/certs
- services.io7api.environment: MQTT_PORT
- services.io7api.environment: MQTT_CONN
- services.io7api.environment: SSL_CERT
- services.io7api.environment: SSL_KEY
- services.io7api.environment: MQTT_SSL_CERT=./cer
- services.io7api.volumes: ./data/certs:/app/certs
- services.io7web.volumes: ./data/certs:/home/node/app/certs
- services.grafana.environment: GF_SERVER_PROTOCOL
- services.grafana.environment: GF_SERVER_CERT_FILE
- services.grafana.environment: GF_SERVER_CERT_KEY
EOF

sudo cp ~/data/mosquitto/config/mosquitto.conf ~/data/mosquitto/config/mosquitto.conf.ssl
sudo node $dir/modify-mosquitto-conf.js ~/data/mosquitto/config/mosquitto.conf <<EOF
listener.8883.port 1883
- listener.1883.keyfile /mosquitto/config/certs/iothub.key
- listener.1883.certfile /mosquitto/config/certs/iothub.crt
- listener.9001.keyfile /mosquitto/config/certs/iothub.key
- listener.9001.certfile /mosquitto/config/certs/iothub.crt
EOF

for d in `find ~/data -type d -name certs`; do sudo rm -rf $d/*; done
docker compose -f ~/docker-compose.yml up -d
