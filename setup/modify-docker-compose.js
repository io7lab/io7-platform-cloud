// Usage: node modify-docker-compose.js <docker-compose.yml>
//
// This tool is used to modify docker-compose.yml file.
//
// The following are the rules to add, remove or modify key value pairs in the dictionary:
//      - services.mqtt.ports: 1883:1883
//      services.mqtt.ports: 8883:8883
//      services.nodered.volumes: ./data/certs:/data/certs
//      services.influxdb.environment: INFLUXD_TLS_CERT=/data/certs/iothub.crt
//      services.influxdb.environment: INFLUXD_TLS_KEY=/data/certs/iothub.key
//
const { parse, stringify } = require('yaml')
const fs = require('fs');
const readline = require('readline');

if (process.argv.length < 3) {
    console.log("\nUsage: node modify-docker-compose.js <docker-compose.yml>");
    console.log("and then enter the key value pairs to add to or remove from the array as follows:\n");
    console.log("services.mqtt.ports: 8883:8883");
    console.log("\t// this adds a new port mapping 8883:8883");
    console.log("\t// the colon means the key object is a block or an array");
    console.log("- services.mqtt.ports: 1883:1883");
    console.log("\t// here '-' means remove this key value pair");
    console.log("services.io7api.command ['uvicorn', 'api:app'] ");
    console.log("\t// this assigns a block or an array to the key");
    process.exit(1);
}

let rl = readline.createInterface({input: process.stdin, output: process.stdout});

let file = process.argv[2];

let yml_text = fs.readFileSync(file, 'utf8');
let jo = parse(yml_text)                // parse yml text to dictionary
let cmd ='';
let key = '';
let value = '';



rl.on('line', line => {

    line = line.trim();
    if (line.length > 1) {              // if line is empty, ignore
        let isBlock = false;
        let remove = false;
        if (line.trim()[0] === '-') {
            remove = true;
            line = line.slice(1).trim();
        }
        let blank = line.indexOf(' ');
        if(blank < 0) {
            key = line;
            value = '';
        } else {
            key = line.slice(0, blank);
            value = line.slice(blank + 1);
        }
        let colon = key.slice(key.length - 1);
        if (colon === ':') {
            isBlock = true;
            key = key.slice(0, key.length - 1);
        }
        
        if (remove) {
            if(isBlock) {
                cmd = `try {jo.${key}=jo.${key}.filter((e) => ! e.includes('${value}'));`;
                cmd += `if (jo.${key}.length === 0) delete jo.${key};`;
                cmd += '} catch(e) {};'
            } else {
                cmd = `try {console.log("delete jo.${key}");delete jo.${key};`;
                cmd += '} catch(e) {};'
            }
        } else {
            if(isBlock) {
                cmd = `try { if (jo.${key} === undefined) jo.${key} =[];`;
                cmd += `let dup = jo.${key}.filter((e) => e.includes('${value}'));`;
                cmd += `if (dup.length === 0) jo.${key}.push('${value}');`;
                cmd += '} catch(e) {};'
            } else {
                cmd = `try {jo.${key} = ${value};`;
                cmd += '} catch(e) {};'
            }
        }
        eval(cmd);
    }
});

rl.on('close', function() {
    fs.writeFileSync(file, stringify(jo))
});
