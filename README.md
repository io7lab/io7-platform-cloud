# ======================= io7 IOT Platform Introduction ========================
I have been using the IBM Watson IOT Foundation to teach the students the Internet of Things at a University. It has been quite comprehensive and concise for the IOT subject, so I really enjoyed it. 

But since it's unfortunetly decided that the IBM Watson IOT Foundation got sunset and no more available, I developed this io7 IOT Platform of a minimum set of IOT platform.

Archtecture and Usage will be documented here soon.

# ======================= Installation ========================

## setup_docker_nodejs.sh
This sets up couple of settings, installs docker and nodejs
It needs to run just once for the Operating system such as AWS EC2 instance or your Linux/Windows.

## io7-platform-setup.sh
This sets up the intial io7 IOT Platform directory structure and calls `io7-platform-reconfig.sh`.
It may be run many times after removing the existing io7 Platform instance. The remving procedure is 
* docker-compose down
* sudo rm -rf ~/data ~/docker-compose.*


## io7-platform-reconfig.sh
This sets the required intitial data such as the admin id, mqttws id and so on. If the io7 Platform instance needs to be clean up, then this script can be run again, then this will reset the data to the initial state.

## io7-platform-secure.sh
This converts the existing non secure io7 Platform instance into TLS protected instance.

## io7-platform-nosecure.sh
This converts back the existing secure io7 Platform instance into non secure instance, ie. no TLS.

## io7-platform-develop.sh
This script is only for development. If you want to develop further on this io7 Platform and to contribute, then use this script to setup the io7 Platform with the source code as well.