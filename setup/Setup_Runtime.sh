#!/bin/bash
#
# This script installs and sets the Runtime environment of the HomeOS
#

echo Visit https://nodejs.org/en/download/ and get the link to the nodejs tarball
echo enter the link here
read url 
if [ -z "$url" ]
then
    echo Skipping the nodejs installation
else
    #wget https://nodejs.org/dist/v18.12.1/node-v18.12.1-linux-arm64.tar.xz
    fname=$(echo $url|awk -F'/' '{ print $NF }')
    rm $fname
    wget $url
    if [ $? -eq 0 ] 
    then
        tar xvf $fname
        cd $(echo $fname|sed 's/.tar.xz$//' | sed 's/.tar.gz$//')
        rm CHANGELOG.md LICENSE README.md
        sudo cp -R * /usr/local
        cd -
        rm -rf $(echo $fname|sed 's/.tar.xz$//' | sed 's/.tar.gz$//')
        sudo npm -g i mqtt basic-auth body-parser cron-parser 
        sudo npm -g i express fs loader node-schedule redis request
    else
        echo check the url for the nodejs
    fi
fi

curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
id pi 2> /dev/null > /dev/null
if [ $? -eq 0 ] ; then
    sudo usermod -aG docker pi
else
    sudo usermod -aG docker ubuntu
fi
sudo systemctl restart containerd
sudo systemctl restart docker.service
sudo apt install docker-compose -y

echo if you are using the serial port device, you need to enable the serial port
