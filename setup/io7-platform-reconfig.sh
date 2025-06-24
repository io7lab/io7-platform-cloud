#!/bin/bash
#
# This script runs the post install procedure
# It should run after making sure the Docker engine is running
sedOpt=
if [ $(uname) = 'Darwin' ]
then
    sedOpt=".bak"
fi

function api_user_create {
	curl $insecure -X 'POST' $proto'://localhost:2009/users/signup' -H 'accept: application/json' \
	  -H 'Content-Type: application/json' \
	  -d '{
	  "username": "API Server user",
	  "email": "'$api_user_email'",
	  "password": "'$api_user_pw'"
	}'
    return $?
}


#main script
if [ "$1" = '-h' ]
then
    echo -e "\n\tUsage: $0 [mqtt_admin_id] [mqtt_admin_pw] [api_user_email] [api_user_pw]\n"
    exit 0
fi
if [ -d ~/data/io7-api-server/data/db ]
then
    echo "Do you want to reset the configuration? (n/y)"
    read reset
    if [ "$reset" != "y" ] && [ "$reset" != "Y" ]
    then
        echo Post Configuration Cancelled.
        exit
    fi
fi

[ -z $1 ]  &&  echo Enter the mqtt dynsec admin id && read admin_id || admin_id=$1
[ -z $2 ]  &&  echo Enter the mqtt dynsec admin password && read admin_pw || admin_pw=$2
[ -z $3 ]  &&  echo Enter the API server user email address && read api_user_email || api_user_email=$3
[ -z $4 ]  &&  echo Enter the API server user password && read api_user_pw || api_user_pw=$4

if [ $(echo $api_user_pw|wc -c) -lt 9 ] ; then
    echo -e "\n\tThe admin password is too short(minimum 8)\n"
    exit 3
fi

docker ps | grep io7api > /dev/null
if [ "$?" -eq 0 ]; then
    docker exec -it io7api rm -rf /app/data/db
    echo Restarting io7api and mqtt. Wait for a few minutes.
fi
docker compose down
sudo rm -rf ~/data/grafana/*
sudo rm -rf ~/data/influxdb/*

insecure=''
proto='http'
if [ -f ~/data/certs/iothub.crt ]; then
  insecure='--insecure'
  proto='https'
fi

docker compose up -d
sleep 10

cd ~
if [ -f ~/data/mosquitto/config/dynamic-security.json ]; then
    docker exec -it mqtt rm /mosquitto/config/dynamic-security.json
fi
docker exec -it mqtt mosquitto_ctrl dynsec init /mosquitto/config/dynamic-security.json $admin_id $admin_pw

echo "MQTT Server is restarting. Wait for a few minutes."
if [ ! -f ~/data/io7-api-server/data/.env ]; then
  cp ~/data/io7-api-server/data/sample.env ~/data/io7-api-server/data/.env
fi
sed -i $sedOpt "s/^DynSecUser=.*/DynSecUser=$admin_id/" ~/data/io7-api-server/data/.env
sed -i $sedOpt "s/^DynSecPass=.*/DynSecPass=$admin_pw/" ~/data/io7-api-server/data/.env

docker compose restart io7api mqtt
sleep 5
# Web Admin id generation in the dynamic-security.json
api_user_create
if [ "$?" -ne "0" ]; then
    sleep 10
    api_user_create
    if [ "$?" -ne "0" ]; then
        echo "API Server is not running. Please check the logs."
        exit 1
    fi
fi

# grafana admin id
docker exec -it grafana grafana cli admin reset-admin-password $api_user_pw
data="{\"email\":\"$api_user_email\",\"name\":\"Admin\",\"login\":\"admin\"}"
curl -X PUT "http://admin:$api_user_pw@localhost:3003/api/users/1" -H "Content-Type: application/json" -d $data

# influxdb admin id
docker exec -it influxdb influx setup --username $api_user_email --password $api_user_pw --org io7org --bucket bucket01 --retention 0 --force
influxdb_token=$(docker exec -it influxdb influx auth list --json|jq '.[0].token'|tr -d \")

# default dashboard setup
dir=$(dirname $(echo $0))
$dir/setup_grafana_dashboard.sh $api_user_email $api_user_pw $influxdb_token
if [ $? -eq 0 ] ; then
    echo All Installatin/Configuration Finished! Happy IOT!!!
else
    echo All Installatin/Configuration Finished except the Grafana Dashboard configuration.
    echo Check the environment and use setup_grafana_dashboard.sh to set it up
fi

docker compose restart io7web 

api_token=$(curl -X POST 'http://localhost:2009/users/login' \
    -H 'Content-Type: application/json' \
    -d "{ \"email\": \"$api_user_email\", \"password\": \"$api_user_pw\" }" \
    |jq '.access_token'|tr -d '"') 2>/dev/null

curl -X 'PUT' "http://localhost:2009/config/influxdb_token" \
  -H 'accept: application/json' -H "Authorization: Bearer $api_token" \
  -H 'Content-Type: application/json' \
  -d "{ \"value\": \"$influxdb_token\" }"

