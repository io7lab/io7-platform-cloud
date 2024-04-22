const { parse, stringify } = require('yaml')
const fs = require('fs');

if (process.argv.length < 3) {
    console.log("Usage: node modify-docker-compose.js <docker-compose.yml> <cafile=none>");
    process.exit(1);
}

let file = process.argv[2];
let cafile = process.argv.length < 4 ? null : process.argv[3];

let data = fs.readFileSync(file, 'utf8');
let jo = parse(data)

if (cafile !== null) {
    jo.services.mqtt.ports = jo.services.mqtt.ports.filter((p) => ! p.includes('1883:'));
    jo.services.mqtt.ports.push('8883:8883');
    
    jo.services.nodered.volumes.push('./data/certs:/data/certs');
    
    jo.services.influxdb.environment.push('INFLUXD_TLS_CERT=/data/certs/iothub.crt');
    jo.services.influxdb.environment.push('INFLUXD_TLS_KEY=/data/certs/iothub.key');
    jo.services.influxdb.volumes.push('./data/certs:/data/certs');
    
    if (!jo.services.io7api.hasOwnProperty('environemnt')) jo.services.io7api.environment = [];
    jo.services.io7api.environment.push('MQTT_CONN=mqtts://mqtt');
    jo.services.io7api.environment.push('SSL_CERT=./certs/iothub.crt');
    jo.services.io7api.environment.push('SSL_KEY=./certs/iothub.key');
    jo.services.io7api.environment.push(`MQTT_SSL_CERT=./certs/${cafile}`);
    jo.services.io7api.environment.push('MQTT_PORT=8883');
    jo.services.io7api.volumes.push('./data/certs:/app/certs');
    
    jo.services.io7web.volumes.push('./data/certs:/home/node/app/certs');
    
    jo.services.grafana.environment.push('GF_SERVER_PROTOCOL=https');
    jo.services.grafana.environment.push('GF_SERVER_CERT_FILE=/var/lib/grafana/certs/iothub.crt');
    jo.services.grafana.environment.push('GF_SERVER_CERT_KEY=/var/lib/grafana/certs/iothub.key');
} else {

    jo.services.mqtt.ports = jo.services.mqtt.ports.filter((p) => ! p.includes('8883:'));
    jo.services.mqtt.ports.push('1883:1883');
    
    jo.services.nodered.volumes = jo.services.nodered.volumes.filter((v)=> !v.includes('./data/certs:/data/certs'));
    
    jo.services.influxdb.environment = jo.services.influxdb.environment.filter((e) => !e.includes('INFLUXD_TLS_CERT'));
    jo.services.influxdb.environment = jo.services.influxdb.environment.filter((e) => !e.includes('INFLUXD_TLS_KEY'));
    jo.services.influxdb.volumes = jo.services.influxdb.volumes.filter((v) => ! v.includes('./data/certs:/data/certs'));

    delete jo.services.io7api['environment'];
    jo.services.io7api.volumes = jo.services.io7api.volumes.filter((p) => !p.includes('./data/certs:/app/certs'));

    jo.services.io7web.volumes = jo.services.io7web.volumes.filter((p) => !p.includes('./data/certs:/home/node/app/certs'));
    
    jo.services.grafana.environment = jo.services.grafana.environment.filter((e) => !e.includes('GF_SERVER_PROTOCOL'));
    jo.services.grafana.environment = jo.services.grafana.environment.filter((e) => !e.includes('GF_SERVER_CERT_FILE'));
    jo.services.grafana.environment = jo.services.grafana.environment.filter((e) => !e.includes('GF_SERVER_CERT_KEY'));
}
fs.writeFileSync(file, stringify(jo))