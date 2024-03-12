#!/bin/bash
#
# This script installs the docker container images for the io7 Cloud Server
# It should run after making sure the Docker engine is running
echo Enter the mqtt dynsec admin id && read admin_id
echo Enter the mqtt dynsec admin password && read admin_pw
echo Enter the API server user email address && read api_user_email
echo Enter the API server user password && read api_user_pw

branch=""
if [ "$1" != "" ]
then
    branch="-b $1"
fi

dir=$(pwd)/$(dirname $(echo $0))
cp $dir/../docker-compose.yml.prod ~/docker-compose.yml
cp -R $dir/../data ~/
[ $(uname) = 'Darwin' ] || sudo chown -R 472:472 ~/data/grafana

cd ~/data/nodered
npm i

cd ~
bash $dir/io7-platform-reconfig.sh $admin_id $admin_pw $api_user_email $api_user_pw
