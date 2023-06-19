dir=$(dirname $(echo $0))

docker-compose -f ~/docker-compose.yml down
sudo mv ~/data/mosquitto/config/mosquitto.conf ~/data/mosquitto/config/mosquitto.conf.nossl
mv ~/docker-compose.yml ~/docker-compose.yml.nossl
mv ~/data/nodered/settings.js ~/data/nodered/settings.js.nossl

cp $dir/secure/docker-compose.yml ~/
sudo cp -p $dir/secure/settings.js ~/data/nodered
sudo cp -p $dir/secure/mosquitto.conf ~/data/mosquitto/config
sedOpt=
if [ $(uname) = 'Darwin' ]
then
    sedOpt=".bak"
fi
sed -i $sedOpt 's/ws:/wss:/' ~/data/io7-management-web/src/pages/mqtt_user.js
cd ~/data/io7-management-web && npm run build

grep -v '^#' ~/data/io7-management-web/docker.run | grep 'ssl-cert' > /dev/null
if [ "$?" -eq 1 ]
then
    sed -i $sedOpt 's/^npx serve -s build/npx serve -s build --ssl-cert ".\/certs\/iothub.crt" --ssl-key ".\/certs\/iothub.key"/'  ~/data/io7-management-web/docker.run
fi

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
