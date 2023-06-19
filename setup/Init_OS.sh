#!/bin/bash
#
# This scripts set the initial RPi OS Environment
#
# .vimrc 
echo set tabstop=4 > ~/.vimrc
echo set shiftwidth=4 >> ~/.vimrc
echo set expandtab >> ~/.vimrc
# timezone and ssh related
sudo raspi-config nonint do_change_timezone Asia/Seoul
sed 's/#UseDNS/UseDNS/' /etc/ssh/sshd_config | sudo tee /etc/ssh/sshd_config
sed 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config | sudo tee /etc/ssh/sshd_config
grep 'set -o vi' ~/.bashrc > /dev/null || echo 'set -o vi' >> ~/.bashrc
#sudo apt update && sudo apt upgrade -y
echo Enter the hostname for the machine
newName=\h
a1='\033[01;32m\]['
a2=']:\w\[\033[00m\]$ '
a12='\\033[01;32m\\]['
a22=']:\\w\[\\033[00m\\]$ '
read newName
if [  "$newName" ]
then
    echo setting the hostname to '"'$newName'"'
    PS1=$(echo $a1$newName$a2)
    #PS1=\033[01;32m\][$newName]:\w\[\033[00m\]$ 
    echo $PS1
    grep $PS1 ~/.bashrc > /dev/null ; echo $?
fi
