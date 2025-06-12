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

echo Enter the mqtt dynsec admin id && read admin_id
echo Enter the mqtt dynsec admin password && read admin_pw
echo Enter the API server user email address && read api_user_email
echo Enter the API server user password && read api_user_pw

if [ $(echo $api_user_pw|wc -c) -lt 9 ] ; then
    echo -e "\n\tThe admin password is too short(minimum 8)\n"
    exit 3
fi

branch=""
if [ "$1" != "" ]
then
    branch="-b $1"
fi

if [ -z $NODE_PATH ] ; then
    export NODE_PATH=$(dirname $(which node))/../lib/node_modules
fi

dir=$(pwd)/$(dirname $(echo $0))
cp $dir/../docker-compose.yml ~/docker-compose.yml
node $dir/modify-docker-compose.js ~/docker-compose.yml <<EOF
- services.io7api.volumes: ./data/io7-api-server/data:/app/data
services.io7api.volumes: ./data/io7-api-server:/app
services.io7api.command [ "uvicorn", "api:app", "--port=2009", "--host=0.0.0.0", "--reload" ]
services.io7web.command [ "npm", "start" ]
services.io7web.volumes: ./data/io7-management-web:/home/node/app
- services.io7web.volumes: ./data/io7-management-web/public/runtime-config.js:/home/node/app/build/runtime-config.js
EOF


if [ $(uname) = 'Linux' ]
then
    git clone $branch git@github.com:io7lab/io7-management-web ~/data/io7-management-web
    git clone $branch git@github.com:io7lab/io7-api-server.git ~/data/io7-api-server
else
    git clone $branch https://github.com/io7lab/io7-management-web.git ~/data/io7-management-web
    git clone $branch https://github.com/io7lab/io7-api-server.git ~/data/io7-api-server
fi

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
fi

cd ~/data/nodered
npm i

cd ~/data/io7-management-web
npm i

cd ~
bash $dir/io7-platform-reconfig.sh $admin_id $admin_pw $api_user_email $api_user_pw
