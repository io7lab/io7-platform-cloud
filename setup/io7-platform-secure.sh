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

mkdir ~/data/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ~/data/certs/iothub.key -out ~/data/certs/iothub.crt
mkdir ~/data/io7-management-web/certs
cp ~/data/certs/* ~/data/io7-management-web/certs
mkdir ~/data/io7-api-server/certs
cp ~/data/certs/* ~/data/io7-api-server/certs
mkdir ~/data/nodered/certs
cp ~/data/certs/* ~/data/nodered/certs
sudo mkdir ~/data/influxdb/certs
sudo cp ~/data/certs/* ~/data/influxdb/certs
docker-compose -f ~/docker-compose.yml up -d
