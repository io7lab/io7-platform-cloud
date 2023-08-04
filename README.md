
Production Environment Setup
* bash io7-platform-cloud/setup/io7-platform-setup.sh

Development Environment Setup
* bash io7-platform-cloud/setup/io7-platform-develop.sh


======================= HomeOS Installation ========================
Init_OS.sh
    This scripts set the initial OS Environment

Setup_Runtime.sh
    This script installs and sets the Runtime environment of the HomeOS
    After running this, it's recommended to reboot the OS

IOTHub_HomeOS.sh
    This script installs the docker container images for the HomeOS
    It should run after making sure the Docker engine is running

================== Redis Init =================
//
// This function node initialize the Redis client
//
const redis = global.get('redis');
const client = redis.createClient( { url: 'redis://redis' } );

client.jget = async k => {
    return {
        d:
            JSON.parse(await client.get(k)),
        time: await client.get(k + ':time')
    };
}

client.connect();
global.set('redisClient', client);

return msg;
================== Securing NodeRED with SSL and Editor Passowrd =================
1. generate the server certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout iothub.key -out iothub.crt

2. Securing the NodeRED with SSL

    vi settings.js

        https: {
            key: require("fs").readFileSync('/data/iothub.key'),
            cert: require("fs").readFileSync('/data/iothub.crt')
        },

3. Securing the NodeRED Editor with user id / password
    docker exec -it nodered node-red admin hash-pw
    Password: 
    $2b$08$9iumJDbhEUUpiG4Md0FP7uDzPLL/9JB0w5IyNMfKxXbjKEUmAQMay

    vi settings.js

        adminAuth: {
	        type: "credentials",
	        users: [{
	            username: "admin",
	            password: "$2b$08$9iumJDbhEUUpiG4Md0FP7uDzPLL/9JB0w5IyNMfKxXbjKEUmAQMay",
	            permissions: "*"
	        }]
	    },

================== Securing Mosquitto with SSL =================
1. Create or use the crt/key generated for NodeRED

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout iothub.key -out iothub.crt

2. vi mosquitto.conf

	# The order of the following lines are important
	listener 8883
	cafile /mosquitto/config/certs/ca.crt
	keyfile /mosquitto/config/certs/iothub.key
	certfile /mosquitto/config/certs/iothub.crt

===================== how to download the/show certificate ======
echo -n | openssl s_client -connect iothub.tosshub.co:1880 -servername iothub.tosshub.co  | openssl x509 > aaa.crt

echo -n | openssl s_client -connect iothub.tosshub.co:8883 -servername iothub.tosshub.co  -showcerts
	
================== How to make a CA and CA Signed Certificate =================
This is for generating a certifcate and the signed server certificate.
It's information only for this project, since the project uses the self signed certificate

	openssl genrsa -des3 -out ca.key 2048
	openssl req -new -x509 -days 365 -key ca.key -out ca.crt
	openssl genrsa -out iothub.key 2048
	openssl req -new -out iothub.csr -key iothub.key 
	openssl x509 -req -in iothub.csr  -CA ca.crt -CAkey ca.key -CAcreateserial -out iothub.crt -days 365