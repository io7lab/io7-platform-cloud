#!/bin/bash
set -x
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

docker-compose -f ~/docker-compose.yml down
sudo mv ~/data/mosquitto/config/mosquitto.conf ~/data/mosquitto/config/mosquitto.conf.nossl
mv ~/docker-compose.yml ~/docker-compose.yml.nossl
mv ~/data/nodered/settings.js ~/data/nodered/settings.js.nossl

cp $dir/secure/docker-compose.yml.ssl ~/docker-compose.yml
if [ "$ca" = "" ]
then
    sed -i $sedOpt 's/MQTT_SSL_CERT=\.\/certs\/.*$/MQTT_SSL_CERT=\.\/certs\/iothub.crt/' ~/docker-compose.yml
else
    cafile=$(basename $ca)
    sed -i $sedOpt "s/MQTT_SSL_CERT=\.\/certs\/.*$/MQTT_SSL_CERT=\.\/certs\/$cafile/" ~/docker-compose.yml
fi


sudo cp -p $dir/secure/settings.js ~/data/nodered
sudo cp -p $dir/secure/mosquitto.conf ~/data/mosquitto/config
sed -i $sedOpt 's/ws:/wss:/' ~/data/io7-management-web/public/runtime-config.js

# if the ownership of the cert files has changed, then try sudo cp
sudo cp ~/data/certs/* ~/data/mosquitto/config/certs
mkdir -p ~/data/nodered/certs
cp ~/data/certs/* ~/data/nodered/certs || sudo cp ~/data/certs/* ~/data/nodered/certs
mkdir -p ~/data/influxdb/certs || sudo mkdir -p ~/data/influxdb/certs
cp ~/data/certs/iothub.* ~/data/influxdb/certs || sudo cp ~/data/certs/iothub.* ~/data/influxdb/certs
docker-compose -f ~/docker-compose.yml up -d
