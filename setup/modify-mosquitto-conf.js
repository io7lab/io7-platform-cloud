// Usage: node modify-mosquitto-conf.js <mosquitto.conf>
//
// This tool is used to modify mosquitto.conf file. It can be used to add, remove or modify listener parameters.
// Except the listener parameters, all other parameters are just added, removed or modified as is.
//
// Since the listener parameters are defined in a block, the tool will first parse the listener parameters and handle them in groups.
// The listener parameters are defined as follows:
//      listener.1883.port
//      listener.1883.protocol mqtt
//      listener.1883.plugin /usr/lib/mosquitto_dynamic_security.so
//      listener.1883.plugin_opt_config_file /mosquitto/config/dynamic-security.json
//      listener.1883.keyfile /mosquitto/config/certs/iothub.key
//      listener.1883.certfile /mosquitto/config/certs/iothub.crt
//
const fs = require('fs');
const readline = require('readline');

if (process.argv.length < 3) {
    console.log("\nUsage: node modify-mosquitto-conf.js <mosquitto.conf>");
    process.exit(1);
}

let listeners= []
/* {
    port : {value: 1883, line: 0},
    protocol: {value: 'mqtt', line: 1},
    plugin: {value: '', line: 2},
    plugin_opt_config_file: {value: '', line: 3},
    keyfile: {value: '', line: 4},
    certfile: {value: '', line: 5},
} */

const listenerKeys = [
    'listener',
    'protocol',
    'plugin',
    'plugin_opt_config_file',
    'keyfile',
    'certfile'
];

let data_file = process.argv[2];
let rl = readline.createInterface({input: process.stdin, output: process.stdout});

let data = fs.readFileSync(data_file, 'utf8');
let cfg_lines = data.split('\n');

function getEndline(obj) {
    let max = 0;
    let l = Object.keys(obj);
    for (p of l) {
        max = obj[p].line > max ? obj[p].line : max;
    }
    return max;
}

function mapListeners() {
    listeners = [];
    let inListner = false;
    let lineIndex = 0;
    let listenerIndex = -1;
    for (let l of cfg_lines) {
        if (listenerKeys.includes(l.trim().split(' ')[0])) {
            if (l.trim().split(' ')[0] === 'listener') {
                inListner = true;
                listenerIndex++;
                listeners.push(
                    {
                        port: { value: l.trim().split(' ')[1], line: lineIndex },
                    }
                );
            } else {
                listeners[listenerIndex][l.trim().split(' ')[0]] = { value: l.trim().split(' ')[1], line: lineIndex };
            }
        } else {
            inListner = false;
        }
        lineIndex++;
    }
}

function lineFor(key) {
    let idx = 0;
    for (let l of cfg_lines) {
        if (l.trim().split(' ')[0] === key) {
            return idx;
        }
        idx++;
    }
    return -1;
}

mapListeners();

rl.on('line', line => {
    line = line.trim();
    if (line === 'l') {console.log(listeners); return;};
    if (line === 'f') { let i = 0;for (let l of cfg_lines) { if (cfg_lines[i] !== undefined) { console.log(i + 1, cfg_lines[i++]); } } return; }

    let remove = false;
    if (line[0] === '-') {
        remove = true;
        line = line.slice(1).trim();
    }
    let key = line.split(' ')[0];
    let value = line.split(' ')[1];
    let port = key.split('.')[1];

    if (port === undefined) {
        let lnum = lineFor(key);
        if (lnum > -1 ) {
            if (remove) {
                cfg_lines = cfg_lines.slice(0, lnum).concat(cfg_lines.slice(lnum + 1));
            } else {
                cfg_lines[lnum] = line;
            }
        } else {
            if (!remove) {
                cfg_lines.push(line);
            }
        }
    } else {
        key = key.split('.')[2] || 'port';
        let obj = listeners.find(l => l.port.value == port);
        if (key === 'port') {
            if (obj === undefined) {
                if (remove) {
                    console.log(`No listener for ${port} found to remove`);
                } else {
                    if (port !== value) console.log(`Port number discrepancy. ${port} will be used.`);
                    cfg_lines.push(`listener ${port}`);
                }
            } else {
                if (remove) {
                    cfg_lines = cfg_lines.slice(0, obj.port.line).concat(cfg_lines.slice(getEndline(obj) + 1));
                } else {
                    cfg_lines[obj.port.line] = `listener ${value}`;
                }
            }
        } else if (obj === undefined) {
            if (listenerKeys.includes(key)) {
                console.log(`No listener for ${port} found to process the parameter (${key})`);
            } else {
                console.log(`No listener for ${port} found and Invalid parameter (${key}) as well`);
            }
        } else {
            let pobj = obj[key];
            if (pobj === undefined) {
                if (remove) {
                    console.log(`No listener parameter(${key}) for ${port} found to remove`);
                } else {
                    if (listenerKeys.includes(key)) {
                        cfg_lines.splice(getEndline(obj) + 1, 0, `${key} ${value}`).concat(cfg_lines.slice(getEndline(obj) + 1));
                    } else {
                        console.log(`Invalid listener parameter(${key}) for ${port}`);
                    }
                }
            } else {
                if (remove) {
                    cfg_lines = cfg_lines.slice(0, pobj.line).concat(cfg_lines.slice(pobj.line + 1));
                } else {
                    cfg_lines[pobj.line] = `${key} ${value}`;
                }
            }
        }
    }
    mapListeners();
});

rl.on('close', function() {
    fs.writeFileSync(data_file, cfg_lines.join('\n'));
});
