#!/bin/bash
sedOpt=
[ $(uname) = 'Darwin' ] && sedOpt=".bak"
LINE=$*
myopt() {
    pname=$1
    echo $(echo $LINE | awk -F"-$pname " '{print $2}'|awk -F" " '{print $1}')
}

echo $LINE | grep -e '-h ' -e '-help ' > /dev/null
if [ "$?" -eq 0 ] ; then
    printf "\n\t Usage : \n\n\t\tbash $0 [-cert certfile] [-ca cafile] [-help /-h ]\n\n"
    exit 0
fi

cert=$(myopt cert)
ca=$(myopt ca)

ssl_file_base=""
[ "$cert" = "" ] ||  ssl_file_base=$(echo $cert| awk -F"." '{print $1}')

mkdir -p ~/data/certs
if [ "$ssl_file_base" = "" ]
then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ~/data/certs/iothub.key -out ~/data/certs/iothub.crt
else
    cp $ssl_file_base.crt ~/data/certs/iothub.crt
    cp $ssl_file_base.key ~/data/certs/iothub.key
    [ "$ca" = "" ] || cp $ca ~/data/certs
fi

dir=$(dirname $(echo $0))

cp ~/docker-compose.yml ~/docker-compose.yml.nossl
[ "$ca" = "" ] && ca='iothub.crt'

node $dir/modify-docker-compose.js ~/docker-compose.yml <<EOF
- services.mqtt.ports: 1883:1883
services.mqtt.ports: 8883:8883
services.nodered.volumes: ./data/certs:/data/certs
services.influxdb.environment: INFLUXD_TLS_CERT=/data/certs/iothub.crt
services.influxdb.environment: INFLUXD_TLS_KEY=/data/certs/iothub.key
services.influxdb.volumes: ./data/certs:/data/certs
services.io7api.environment: MQTT_CONN=mqtts://mqtt
services.io7api.environment: SSL_CERT=./certs/iothub.crt
services.io7api.environment: SSL_KEY=./certs/iothub.key
services.io7api.environment: MQTT_SSL_CERT=./certs/$ca
services.io7api.environment: MQTT_PORT=8883
services.io7api.volumes: ./data/certs:/app/certs
services.io7web.volumes: ./data/certs:/home/node/app/certs
services.grafana.environment: GF_SERVER_PROTOCOL=https
services.grafana.environment: GF_SERVER_CERT_FILE=/var/lib/grafana/certs/iothub.crt
services.grafana.environment: GF_SERVER_CERT_KEY=/var/lib/grafana/certs/iothub.key
EOF

sudo cp -p ~/data/nodered/settings.js ~/data/nodered/settings.js.nossl
docker exec -i nodered /usr/local/bin/node /data/check.js /data/settings.js  << EOF
https: {
  key: require("fs").readFileSync("/data/certs/iothub.key"),
  cert: require("fs").readFileSync("/data/certs/iothub.key")
},
EOF

docker compose -f ~/docker-compose.yml down
sudo mv ~/data/mosquitto/config/mosquitto.conf ~/data/mosquitto/config/mosquitto.conf.nossl
sudo cp -p $dir/secure/mosquitto.conf ~/data/mosquitto/config
sed -i $sedOpt 's/ws:/wss:/' ~/data/io7-management-web/public/runtime-config.js

[ -d ~/data/mosquitto/config/certs ] || sudo mkdir -p ~/data/mosquitto/config/certs
sudo cp ~/data/certs/* ~/data/mosquitto/config/certs
sudo chown -R 1883:1883 ~/data/mosquitto/config/certs

[ -d ~/data/grafana/certs ] || sudo mkdir -p ~/data/grafana/certs
sudo cp ~/data/certs/* ~/data/grafana/certs
sudo chown -R 472:472 ~/data/grafana/certs

docker compose -f ~/docker-compose.yml up -d