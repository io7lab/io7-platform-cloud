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
#sudo apt update && sudo apt upgrade -y
echo Enter the hostname for the machine
read newName
if [  "$newName" ]
then
    sudo hostname $newName
    echo logout and login again to have the new PS1 in effect
fi
# end of environment setup
# start of docker and nodejs setup
if [ $(uname) = 'Linux' ]
then
    sudo apt install nodejs npm
else
    echo "This script is for Linux only"
    echo "If you are using Windows or Mac, then install and configure the following"
    echo -e "\t1. nodejs and npm"
    echo -e "\t2. docker"
    exit 1
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
