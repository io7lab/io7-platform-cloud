import paho.mqtt.client as mqtt
import ssl
#server = "127.0.0.1"
server = "iothub.tosshub.co"

def on_connect(client, userdata, flags, rc):
    print("Connected with RC : " + str(rc))
    client.subscribe("test/#")

def on_message(client, userdata, msg):
    print(msg.topic+" "+msg.payload.decode('utf-8'))

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.tls_set("iothub.crt", tls_version=ssl.PROTOCOL_TLSv1_2)
client.tls_insecure_set(True)
client.connect(server, 8883, 60)

client.loop_forever()
