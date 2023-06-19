const mqtt = require('mqtt');
const fs = require('fs');

const configFile = fs.readFileSync('./config.json', 'utf8');
const cfg = JSON.parse(configFile);
const clientOption = cfg.clientOption;
const gatewayId = cfg.clientOption.username;

const cloud  = mqtt.connect(cfg.cloud, clientOption);
const bridge  = mqtt.connect(cfg.bridge);

let edgeDevices = [];

let sub4cloud = (device) => {
    console.log('subscribing for ' + device);
    cloud.subscribe(`iot3/${device}/cmd/+/fmt/+`);
    cloud.subscribe(`iot3/${device}/mgmt/initiate/device/reboot`);
    cloud.subscribe(`iot3/${device}/mgmt/device/update`);
    cloud.subscribe(`iot3/${device}/mgmt/device/update`);
    cloud.subscribe(`iot3/${device}/mgmt/initiate/device/factory_reset`);
    cloud.subscribe(`iot3/${device}/mgmt/initiate/firmware/update`);
}

cloud.on('connect', () => {
    cloud.subscribe(`iot3/${gatewayId}/gateway/list`);
    cloud.publish(`iot3/${gatewayId}/gateway/query`, '{"d":{"devices":"*"}}');
});

setTimeout(() => {
    bridge.on('connect', () => {
        bridge.subscribe(`iot3/+/evt/+/fmt/+`);
        bridge.subscribe(`iot3/+/mgmt/device/meta`);
    });
}, 2);

cloud.on('message', (topic, message) => {
    if ( topic === `iot3/${gatewayId}/gateway/list` ) {
        const list = JSON.parse(message.toString());

        edgeDevices = [];
        list.forEach(d => {
            edgeDevices.push(d);
            sub4cloud(d);
        })
    } else {
        bridge.publish(topic, message.toString());
    }
});

bridge.on('message', (topic, message) => {
    const topic_ = topic.split('/');
    if (edgeDevices.includes(topic_[1])) {
        if (topic_[3] === 'connection' || topic_[4] === 'meta') {
            cloud.publish(topic, message.toString(), { retain: true });
        } else {
            cloud.publish(topic, message.toString());
        }
    } else {

        if (topic_[3] !== 'connection' && topic_[4] !== 'meta') {
            // skipping all the retained messages
            cloud.publish(`iot3/${gatewayId}/gateway/add`, `{"d":{"devId":"${topic_[1]}"}}`);
        }
    }
});