#!/bin/bash
#
# This script installs the docker container images for the io7 Cloud Server
# It should run after making sure the Docker engine is running
node -v > /dev/null
if [ $? -ne 0 ]; then
    echo "Please install Node.js before running this script"
    exit 1
fi
docker --version > /dev/null
if [ $? -ne 0 ]; then
    echo "Please install Docker before running this script"
    exit 1
fi
if [ "$#" -eq 0 ]; then
    echo Enter the mqtt dynsec admin id && read admin_id
    echo Enter the mqtt dynsec admin password && read admin_pw
    echo Enter the API server user email address && read api_user_email
    echo Enter the API server user password && read api_user_pw
elif [ "$#" -eq 4 ]; then
    admin_id=$1
    admin_pw=$2
    api_user_email=$3
    api_user_pw=$4
else
    echo -e "\n\tUsage: $0 [mqtt_admin_id mqtt_admin_pw api_user_email api_user_pw]"
    echo -e "\nRun this command either with all 4 parameters or without any of them\n"
    exit 2
fi

if [ $(echo $api_user_pw|wc -c) -lt 9 ] ; then
    echo -e "\n\tThe admin password is too short(minimum 8)\n"
    exit 3
fi

branch=""
if [ "$1" != "" ]
then
    branch="-b $1"
fi

dir=$(pwd)/$(dirname $(echo $0))
cp $dir/../docker-compose.yml ~/docker-compose.yml
cp -R $dir/../data ~/
[ -d ~/data/grafana ] || mkdir -p ~/data/grafana
if [ $(uname) = 'Linux' ]; then
    sudo chown -R 472:472 ~/data/grafana
    if [ $(uname -a|awk '{print $(NF-1)}') == 'x86_64' ]; then
        (cd ~/data/mosquitto/lib ; ln -s io7_jwt_security.so.amd64 io7_jwt_security.so)
    elif [ $(uname -a|awk '{print $(NF-1)}') == 'aarch64' ]; then
        (cd ~/data/mosquitto/lib ; ln -s io7_jwt_security.so.aarch64 io7_jwt_security.so)
    fi
elif [ $(uname -m) == 'arm64' ]; then
    (cd ~/data/mosquitto/lib; ln -s io7_jwt_security.so.aarch64 io7_jwt_security.so)
else
    (cd ~/data/mosquitto/lib; ln -s io7_jwt_security.so.amd64 io7_jwt_security.so)
fi

cd ~/data/nodered
npm i

cd ~
bash $dir/io7-platform-reconfig.sh $admin_id $admin_pw $api_user_email $api_user_pw
