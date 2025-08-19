# io7 IOT Platform Introduction
---
The IBM Watson IOT Foundation had been my choice of platform to teach the students the Internet of Things at a University with. It was a quite comprehensive and concise for the IOT subject, so it was much appreciated and enjoyed. 

But it's unfortunetly decided that the IBM Watson IOT Foundation got sunset and no more available, so this io7 IOT Platform of a minimum set of IOT platform has been developed.

The main purpose of developing this platform and the submodules is to take the essential concepts from the IBM Watson IOT and to come up with a minimum but all required features with which the students can learn and practice the Internet of Things.

--- 

![259081527-279e44bc-265c-4149-9b36-d10a3ace046f](https://github.com/io7lab/io7-platform-cloud/assets/13171662/e07132d7-ed5b-4601-953b-e88481724b1c)

### This is the message subscription and publication authorization for the devices and the application id.
![Screenshot 2024-04-12 at 10 40 32 AM](https://github.com/io7lab/.github/assets/13171662/8da6b017-b74c-4e04-ada8-c2645bd57f56)

### This is the architecture diagram.

<p align="center">
  <img width="1350" alt="Screenshot 2024-03-22 at 2 42 40 PM" src="https://github.com/io7lab/io7-platform-cloud/assets/13171662/a279d954-6b43-421d-8588-b54fccc5e3a6">
</p>
<p align="center"><strong>io7 IOT Platform Architecture</strong></p>

<p align="center">
<img width="1238" height="1408" alt="Screenshot 2025-07-15 at 5 01 41 PM" src="https://github.com/user-attachments/assets/fea06c7a-e46d-4ca9-b95f-803b1c381dcc" /></p>
<p align="center"><strong>io7 Management Web Console</strong></p>


# Github repositories for the io7 Platform
**Brief diagram of the io7 Platform components.**

1. https://github.com/io7lab/io7-platform-cloud : the current Repository. This has the installation shell scripts which will install the following components of the io7 IOT Platform server on a Linux server such as an AWS EC2 instance or a dedicated server.
    1. https://github.com/io7lab/io7-api-server : the REST API Server which handles the Device registration and deregistration as well as the Application Key. This is a part of the io7 IOT Platform server.
    2. https://github.com/io7lab/io7-management-web : the Web frontend to the io7 Platform. This is a part of the io7 IOT Platform server.
    3. https://github.com/io7lab/node-red-contrib-io7 : NodeRED node that makes it easy to develop the NodeRED flow with. It's the equivalent to node-red-contrib-scx-ibmiotapp for the io7. This is a part of the io7 IOT Platform server.
    4. https://github.com/io7lab/io7_jwt_security : the Mosquitto plugin to reuse the Management Web's JWT as the MQTT over WebSocket connection credential.
    5. https://github.com/io7lab/io7-nodered-auth : the node package for the NodeRED admin authentication against io7 API server.
2. https://github.com/io7lab/IO7F8266 : ESP8266 Arduino Library which helps develop the Arduino io7 device easily.
3. https://github.com/io7lab/IO7F32 : ESP32 Arduino Library which helps develop the Arduino io7 device easily.
4. https://github.com/io7lab/IO7FuPython : ESP32 Micropython Library which helps develop the Micropython io7 device easily.
5. https://github.com/io7lab/io7-platform-edge : this repository is for the Edge Server with a Raspberry Pi. This implements an io7 gateway that sits between the local mosquitto broker on the RPi and the io7 Cloud broker and represents the local io7 edge devices by requesting automatic registration and relaying the mqtt events and commands. This prvodes the Edge Server level NodeRED so the Edge level intelligence can be implemented there.
6. https://github.com/io7lab/io7dummy-device : io7 dummy IOT Device. This emulates the io7 IOT Device and can be used to do a quick check after the io7 IOT Platform setup.

# Quick Installation

Create a linux instance like AWS EC2 and run the following.
```
git clone https://github.com/io7lab/io7-platform-cloud.git
bash io7-platform-cloud/setup/setup_docker_nodejs.sh
exit
```
login again and run the following to install io7 platform server. 
```
bash io7-platform-cloud/setup/io7-platform-setup.sh
```
You will need to provide with
* mqtt id  : mosquitto dynamic security id
* mqtt pw  : mosquitto dynamic security password
* admin id : admin id in the form of email address. This is the management web login id.
* admin pw : admin password.
and you can access http://yourserver:3000 to register the deivces and the application key.

# Installation and Utility scripts

## setup_docker_nodejs.sh
This sets up couple of settings, installs docker and nodejs.
It needs to run just once for the Operating system such as AWS EC2 instance or your Linux/Windows.

## io7-platform-setup.sh
This sets up the intial io7 IOT Platform directory structure and calls `io7-platform-reconfig.sh`.
It may be run many times after removing the existing io7 Platform instance. The remving procedure is 
* docker compose down
* sudo rm -rf ~/data ~/docker-compose.*

## io7-platform-reconfig.sh
This sets the required intitial data such as the admin id, mqttws id and so on. If the io7 Platform instance needs to be clean up without the reinstallation, then this script can be run again, then it will reset the data to the initial state.

## get_letsencrypt_cert.sh
This scripts gets the CA trusted certificates for your fully qualified domain name, create cert.crt/cert.key for the subject host and the ca.pem for the CA chain. After getting the certificates with this script, run `io7-platform-secure.sh -ca ca.pem -cert cert.crt -fqdn your.domain.com` to harden the security with the SSL.

## io7-platform-secure.sh
This converts the existing non secure io7 Platform instance into TLS protected instance. In order to get the publicly accepted certificates for the TLS communication, `get_letsencrypt_cert.sh` should be run before this script. 

## io7-platform-nosecure.sh
This converts back the existing secure io7 Platform instance into non secure instance, ie. no TLS.

## io7-platform-develop.sh
This script is only for development. If you want to develop further on this io7 Platform and to contribute, then use this script in stead of `io7-platform-setup.sh` . This sets up the io7 Platform with the source code as well, so you can learn the code and/or improve on your own.
