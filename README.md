# io7 IOT Platform Introduction
I have been using the IBM Watson IOT Foundation to teach the students the Internet of Things at a University. It has been quite comprehensive and concise for the IOT subject, so I really enjoyed it. 

But since it's unfortunetly decided that the IBM Watson IOT Foundation got sunset and no more available, I developed this io7 IOT Platform of a minimum set of IOT platform.

The main purpose of developing this platform and the submodules is to take the essential concepts from the IBM Watson IOT and to come up with a minimum but all required features with which the students can learn and practice the Internet of Things.

**It's been an one man shop development, so it is not a corporate quality and contents, but I hope it is good enough for teaching and learning. And I would welcome any suggestion, adoption, and possibly collaboration and contribution.**


<img width="800" alt="Screenshot 2023-08-08 at 8 12 51 PM" src="https://github.com/io7lab/io7-platform-cloud/assets/13171662/279e44bc-265c-4149-9b36-d10a3ace046f">

*Archtecture and Usage will be further documented here soon.*

# Github repositories for the io7 Platform

1. https://github.com/io7lab/io7-platform-cloud : the current Repository
2. https://github.com/io7lab/io7-api-server : the REST API Server which handles the Device registration and deregistration as well as the Application Key.
3. https://github.com/io7lab/io7-management-web : the Web frontend to the io7 Platform.
4. https://github.com/io7lab/node-red-contrib-io7 : NodeRED node that makes it easy to develop the NodeRED flow with. It's the equivalent to node-red-contrib-scx-ibmiotapp for the io7.
5. https://github.com/io7lab/IO7F8266 : ESP8266 Arduino Library which helps develop the Arduino io7 device easily.
6. https://github.com/io7lab/IO7FuPython : ESP32 Micropython Library which helps develop the Micropython io7 device easily.
7. https://github.com/io7lab/io7-platform-edge : this repository is for the Edge Server with a Raspberry Pi. This implements an io7 gateway that sits between the local mosquitto broker on the RPi and the io7 Cloud broker and represents the local io7 edge devices by requesting automatic registration and relaying the mqtt events and commands.

<img width="800" alt="Screenshot 2023-08-08 at 8 17 33 PM" src="https://github.com/io7lab/io7-platform-cloud/assets/13171662/13dcad6c-941e-4ff6-a836-8d27e1067aa9">


# Quick Installation

Create a linux instance like AWS EC2 and run the following.
```
git clone git@github.com:io7lab/io7-platform-cloud.git
bash io7-platform-cloud/setup/setup_docker_nodejs.sh
sudo reboot
```
login again and run the following. You will need to provide
* mqtt id  : mosquitto dynamic security id
* mqtt pw  : mosquitto dynamic security password
* admin id : admin id in the form of email address. This is the management web login id.
* admin pw : admin password.

```
bash io7-platform-cloud/setup/io7-platform-setup.sh
```
and you can access http://yourserver:3000 to register the deivces and the application key.

# Installation and Utility scripts

## setup_docker_nodejs.sh
This sets up couple of settings, installs docker and nodejs.
It needs to run just once for the Operating system such as AWS EC2 instance or your Linux/Windows.

## io7-platform-setup.sh
This sets up the intial io7 IOT Platform directory structure and calls `io7-platform-reconfig.sh`.
It may be run many times after removing the existing io7 Platform instance. The remving procedure is 
* docker-compose down
* sudo rm -rf ~/data ~/docker-compose.*


## io7-platform-reconfig.sh
This sets the required intitial data such as the admin id, mqttws id and so on. If the io7 Platform instance needs to be clean up without the reinstallation, then this script can be run again, then it will reset the data to the initial state.

## io7-platform-secure.sh
This converts the existing non secure io7 Platform instance into TLS protected instance.

## io7-platform-nosecure.sh
This converts back the existing secure io7 Platform instance into non secure instance, ie. no TLS.

## io7-platform-develop.sh
This script is only for development. If you want to develop further on this io7 Platform and to contribute, then use this script to setup the io7 Platform with the source code as well.
