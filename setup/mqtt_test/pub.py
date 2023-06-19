import sys
import ssl
import paho.mqtt.client as mqtt
#server = "127.0.0.1"
server = "iothub.tosshub.co" 

client = mqtt.Client()
client.tls_set("iothub.crt", tls_version=ssl.PROTOCOL_TLSv1_2)
client.tls_insecure_set(True)
client.connect(server, 8883, 60)

if len(sys.argv) <= 1:
    print("Usage : "+sys.argv[0]+" message")
    exit()
else:
    client.publish("test/goodluck", str(sys.argv[1]))
