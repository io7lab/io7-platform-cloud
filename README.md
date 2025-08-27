
# io7 IoT Platform Introduction
---
The IBM Watson IoT Foundation was my preferred platform for teaching students about the Internet of Things at university. It was comprehensive and concise for the IoT subject, and was much appreciated and enjoyed.

Unfortunately, the IBM Watson IoT Foundation was sunset and is no longer available. As a result, the io7 IoT Platform was developed to provide a minimal yet complete set of IoT platform features.

The main purpose of developing this platform and its submodules is to extract the essential concepts from IBM Watson IoT and create a minimal platform with all the required features for students to learn and practice the Internet of Things.

---

![259081527-279e44bc-265c-4149-9b36-d10a3ace046f](https://github.com/io7lab/io7-platform-cloud/assets/13171662/e07132d7-ed5b-4601-953b-e88481724b1c)

### Message subscription and publication authorization for devices and application IDs
![Screenshot 2024-04-12 at 10 40 32 AM](https://github.com/io7lab/.github/assets/13171662/8da6b017-b74c-4e04-ada8-c2645bd57f56)

### Architecture diagram

<p align="center">
  <img width="1350" alt="Screenshot 2024-03-22 at 2 42 40 PM" src="https://github.com/io7lab/io7-platform-cloud/assets/13171662/a279d954-6b43-421d-8588-b54fccc5e3a6">
</p>
<p align="center"><strong>io7 IOT Platform Architecture</strong></p>

<p align="center">
<img width="1238" height="1408" alt="Screenshot 2025-07-15 at 5 01 41 PM" src="https://github.com/user-attachments/assets/fea06c7a-e46d-4ca9-b95f-803b1c381dcc" /></p>
<p align="center"><strong>io7 Management Web Console</strong></p>



# GitHub repositories for the io7 Platform
**Brief overview of the io7 Platform components:**


1. https://github.com/io7lab/io7-platform-cloud : The current repository. It contains installation shell scripts to install the following components of the io7 IoT Platform server on a Linux server, such as an AWS EC2 instance or a dedicated server.
    1. https://github.com/io7lab/io7-api-server : The REST API server that handles device registration, deregistration, and application keys. Part of the io7 IoT Platform server.
    2. https://github.com/io7lab/io7-management-web : The web frontend for the io7 Platform. Part of the io7 IoT Platform server.
    3. https://github.com/io7lab/node-red-contrib-io7 : NodeRED node that makes it easy to develop NodeRED flows. Equivalent to node-red-contrib-scx-ibmiotapp for io7. Part of the io7 IoT Platform server.
    4. https://github.com/io7lab/io7_jwt_security : Mosquitto plugin to reuse the Management Web's JWT as the MQTT over WebSocket connection credential.
    5. https://github.com/io7lab/io7-nodered-auth : Node package for NodeRED admin authentication against the io7 API server.
2. https://github.com/io7lab/IO7F8266 : ESP8266 Arduino library to help develop Arduino io7 devices easily.
3. https://github.com/io7lab/IO7F32 : ESP32 Arduino library to help develop Arduino io7 devices easily.
4. https://github.com/io7lab/IO7FuPython : ESP32 Micropython library to help develop Micropython io7 devices easily.
5. https://github.com/io7lab/io7-platform-edge : Repository for the Edge Server with a Raspberry Pi. Implements an io7 gateway that sits between the local Mosquitto broker on the RPi and the io7 Cloud broker, representing local io7 edge devices by requesting automatic registration and relaying MQTT events and commands. Provides Edge Server level NodeRED for implementing edge intelligence.
6. https://github.com/io7lab/io7dummy-device : io7 dummy IoT device. Emulates an io7 IoT device and can be used for quick checks after io7 Platform setup.


# Quick Installation
**This youtube video(https://www.youtube.com/watch?v=18xfq__oo4E) shows the following steps**


Create a Linux instance (e.g., AWS EC2) and run the following:
```
git clone https://github.com/io7lab/io7-platform-cloud.git
bash io7-platform-cloud/setup/setup_docker_nodejs.sh
exit
```
Log in again and run the following to install the io7 platform server:
```
bash io7-platform-cloud/setup/io7-platform-setup.sh
```
You will need to provide:
* mqtt id  : Mosquitto dynamic security ID
* mqtt pw  : Mosquitto dynamic security password
* admin id : Admin ID in the form of an email address (used for management web login)
* admin pw : Admin password

You can then access http://yourserver:3000 to register devices and application keys.


# Installation and Utility Scripts

## setup_docker_nodejs.sh
Sets up required settings, installs Docker and Node.js.
Run this once for the operating system (e.g., AWS EC2 instance, Linux, or Windows).

## io7-platform-setup.sh
Sets up the initial io7 IoT Platform directory structure and calls `io7-platform-reconfig.sh`.
You may run this multiple times after removing the existing io7 Platform instance. To remove the instance:
* docker compose down
* sudo rm -rf ~/data ~/docker-compose.*

## io7-platform-reconfig.sh
Sets the required initial data, such as the admin ID, mqttws ID, and so on. If you need to reset the io7 Platform instance without reinstalling, run this script again to reset the data to its initial state.

## get_letsencrypt_cert.sh
Obtains CA-trusted certificates for your fully qualified domain name, creating cert.crt/cert.key for the host and ca.pem for the CA chain. After obtaining the certificates, run `io7-platform-secure.sh -ca ca.pem -cert cert.crt -fqdn your.domain.com` to enable SSL security.

## io7-platform-secure.sh
Converts an existing non-secure io7 Platform instance into a TLS-protected instance. To obtain publicly accepted certificates for TLS communication, run `get_letsencrypt_cert.sh` before this script.

## io7-platform-nonsecure.sh
Converts a secure io7 Platform instance back to a non-secure instance (i.e., disables TLS).

## io7-platform-develop.sh
This script is for development only. If you want to further develop for your own customization or contribute to the io7 Platform, use this script instead of `io7-platform-setup.sh`. It sets up the io7 Platform with the source code so you can learn and improve it on your own.
