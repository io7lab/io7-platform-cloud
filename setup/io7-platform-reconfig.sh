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

docker exec -it io7api rm -rf /app/data/db/*
echo Restarting io7api and mqtt. Wait for a few minutes.
docker-compose down

insecure=''
proto='http'
if [ -f ~/data/certs/iothub.crt ]
then
  insecure='--insecure'
  proto='https'
fi

cd ~
docker-compose up -d mqtt
sleep 5
docker exec -it mqtt rm /mosquitto/config/dynamic-security.json
docker exec -it mqtt mosquitto_ctrl dynsec init /mosquitto/config/dynamic-security.json $admin_id $admin_pw
docker restart mqtt
if [ ! -f ~/data/io7-api-server/data/.env ]
then
  cp ~/data/io7-api-server/data/sample.env ~/data/io7-api-server/data/.env
fi
sed -i $sedOpt "s/^DynSecUser=.*/DynSecUser=$admin_id/" ~/data/io7-api-server/data/.env
sed -i $sedOpt "s/^DynSecPass=.*/DynSecPass=$admin_pw/" ~/data/io7-api-server/data/.env
docker-compose up -d io7api
sleep 5

docker inspect --format='{{.Config.ExposedPorts}}' mqtt|grep 8883 > /dev/null
if [ "$?" -eq 0 ] ; then
    docker exec -it io7api python /app/dynsec/create_web_user.py -u $admin_id -P $admin_pw -h mqtt -c /app/certs/io7lab.pem > runtime-config.js
else
    docker exec -it io7api python /app/dynsec/create_web_user.py -u $admin_id -P $admin_pw -h mqtt > runtime-config.js
fi

mv runtime-config.js ~/data/io7-management-web/public

# Web Admin id generation in the dynamic-security.json
api_user_create
if [ "$?" -eq "52" ]
then
    sleep 10
    api_user_create
    if [ "$?" -eq "52" ]
    then
        echo "API Server is not running. Please check the logs."
        exit 1
    fi
fi

docker-compose down
docker-compose up -d
echo All Installatin/Configuration Finished! Happy IOT!!!
