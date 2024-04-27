#!/bin/bash
#
# This script installs and sets the Runtime environment of the HomeOS
#
echo set tabstop=4 > ~/.vimrc
echo set shiftwidth=4 >> ~/.vimrc
echo set expandtab >> ~/.vimrc
# timezone and ssh related
sed 's/#UseDNS/UseDNS/' /etc/ssh/sshd_config | sudo tee /etc/ssh/sshd_config
sed 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config | sudo tee /etc/ssh/sshd_config
grep 'set -o vi' ~/.bashrc > /dev/null || echo 'set -o vi' >> ~/.bashrc
echo export NODE_PATH=/usr/local/lib/node_modules:\$NODE_PATH >> ~/.bashrc
#sudo apt update && sudo apt upgrade -y
echo Enter the hostname for the machine
read newName
if [  "$newName" ]
then
    sudo hostname $newName
    echo $newName | sudo tee /etc/hostname
    echo logout and login again to have the new PS1 in effect
fi
# end of environment setup
# start of docker and nodejs setup
if [ $(uname) = 'Linux' ]
then
    if [ $(uname -m) = 'x86_64' ]
    then
        nodejs_url='https://nodejs.org/dist/v20.11.1/node-v20.11.1-linux-x64.tar.xz'
    else
        nodejs_url='https://nodejs.org/dist/v20.11.1/node-v20.11.1-linux-arm64.tar.xz'
    fi
else
    echo "This script is for Linux only"
    echo "If you are using Windows or Mac, then install and configure the following"
    echo -e "\t1. nodejs and npm"
    echo -e "\t2. docker"
    exit 1
fi

echo "nodejs will be installed for the link =>"
echo "        " $nodejs_url
echo "if you you want to install a different version or the latest if any"
echo "then visit https://nodejs.org/en/download/ and get the link to the nodejs tarball"
echo "paste the link here, otherwise just hit enter"

read url
if [ -z "$url" ]
then
    url=$nodejs_url
fi

fname=$(echo $url|awk -F'/' '{ print $NF }')
test -f $fname && rm $fname
wget $url
if [ $? -eq 0 ] 
then
    tar xvf $fname
    cd $(echo $fname|sed 's/.tar.xz$//' | sed 's/.tar.gz$//')
    rm CHANGELOG.md LICENSE README.md
    sudo cp -R * /usr/local
    cd -
    rm -rf $(echo $fname|sed 's/.tar.xz$//' | sed 's/.tar.gz$//')
    sudo npm -g i mqtt basic-auth body-parser cron-parser yaml
    sudo npm -g i express fs loader node-schedule redis request
else
    echo check the url for the nodejs
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
