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
cp $dir/../docker-compose.yml.dev ~/docker-compose.yml
if [ $(uname) = 'Linux' ]
then
    git clone $branch git@github.com:io7lab/io7-management-web ~/data/io7-management-web
    git clone $branch git@github.com:io7lab/io7-api-server.git ~/data/io7-api-server
else
    git clone $branch https://github.com/io7lab/io7-management-web.git ~/data/io7-management-web
    git clone $branch https://github.com/io7lab/io7-api-server.git ~/data/io7-api-server
fi
cp -R $dir/../data ~/

cd ~/data/nodered
npm i

cd ~/data/io7-management-web
npm i

cd ~
bash $dir/io7-platform-post.sh $admin_id $admin_pw $api_user_email $api_user_pw
