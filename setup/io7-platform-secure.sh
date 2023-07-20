ssl_file_base=""
if [ "$1" != "" ]
then
    ssl_file_base=$(echo $1| awk -F"." '{print $1}')
fi
dir=$(dirname $(echo $0))

docker-compose -f ~/docker-compose.yml down
sudo mv ~/data/mosquitto/config/mosquitto.conf ~/data/mosquitto/config/mosquitto.conf.nossl
mv ~/docker-compose.yml ~/docker-compose.yml.nossl
mv ~/data/nodered/settings.js ~/data/nodered/settings.js.nossl

cp $dir/secure/docker-compose.yml.ssl ~/docker-compose.yml
sudo cp -p $dir/secure/settings.js ~/data/nodered
sudo cp -p $dir/secure/mosquitto.conf ~/data/mosquitto/config
sedOpt=
if [ $(uname) = 'Darwin' ]
then
    sedOpt=".bak"
fi
sed -i $sedOpt 's/ws:/wss:/' ~/data/io7-management-web/public/runtime-config.js

mkdir -p ~/data/certs
if [ "$ssl_file_base" = "" ]
then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ~/data/certs/iothub.key -out ~/data/certs/iothub.crt
else
    cp $ssl_file_base.crt ~/data/certs/iothub.crt
    cp $ssl_file_base.key ~/data/certs/iothub.key
fi

mkdir -p ~/data/io7-management-web/certs
cp ~/data/certs/* ~/data/io7-management-web/certs || sudo cp ~/data/certs/* ~/data/io7-management-web/certs
# if the ownership of the cert files has changed, then sudo cp
mkdir -p ~/data/io7-api-server/certs
cp ~/data/certs/* ~/data/io7-api-server/certs || sudo cp ~/data/certs/* ~/data/io7-api-server/certs
mkdir -p ~/data/nodered/certs
cp ~/data/certs/* ~/data/nodered/certs || sudo cp ~/data/certs/* ~/data/nodered/certs
mkdir -p ~/data/influxdb/certs
cp ~/data/certs/* ~/data/influxdb/certs || sudo cp ~/data/certs/* ~/data/influxdb/certs
docker-compose -f ~/docker-compose.yml up -d
