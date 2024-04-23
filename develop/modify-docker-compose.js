const { parse, stringify } = require('yaml')
const fs = require('fs');
const readline = require('readline');

if (process.argv.length < 3) {
    console.log("\nUsage: node modify-docker-compose.js <docker-compose.yml>");
    console.log("and then enter the key value pairs to add or remove as follows:\n");
    console.log("services.mqtt.ports 8883:8883");
    console.log("\t// this adds a new port mapping 8883:8883");
    console.log("services.mqtt.ports 1883:1883 -");
    console.log("\t// here '-' means remove this key value pair");
    process.exit(1);
}

let rl = readline.createInterface({input: process.stdin, output: process.stdout});

let file = process.argv[2];

let data = fs.readFileSync(file, 'utf8');
let jo = parse(data)
let cmd ='';

rl.on('line', data => {

    data = data.trim();
    if (data.length > 1) {              // if data is empty, ignore
        let remove = data[data.length - 1] === '-' ? true : false;
        if (remove) {
            data = data.slice(0, -1).trim();
        }
        let blank = data.indexOf(' ');
        let key = data.slice(0, blank);
        let value = data.slice(blank + 1);
        
        if (remove) {
            cmd = `try {jo.${key}=jo.${key}.filter((e) => ! e.includes('${value}'));`;
            cmd += `if (jo.${key}.length === 0) delete jo.${key};`;
            cmd += '} catch(e) {};'
            eval(cmd);
        } else {
            cmd = `try { if (jo.${key} === undefined) jo.${key} =[];`;
            cmd += `let dup = jo.${key}.filter((e) => e.includes('${value}'));`;
            cmd += `if (dup.length === 0) jo.${key}.push('${value}');`;
            cmd += '} catch(e) {};'
            eval(cmd);
        }
    }
});

rl.on('close', function() {
    fs.writeFileSync(file, stringify(jo))
});
