// Usage: node modify-nodered-settings.js <settings.js>
//
// This tool is used to modify settings.js file for the NodeRED.
//
// The following is the way to add, remove or modify key value pairs.
//      docker exec -i nodered /usr/local/bin/node /data/check.js /data/settings.js  << EOF
//      https: {
//        key: require("fs").readFileSync("/data/certs/iothub.key"),
//        cert: require("fs").readFileSync("/data/certs/iothub.key")
//      },
//      EOF
//
// For removing a block, add '-' before the key and { or require, since the block would and with }, or }) respectively.
// the end of block(ie. '},' or '}),') is automatically determined.
//
//      docker exec -i nodered /usr/local/bin/node /tmp/modify-nodered-settings.js /data/settings.js  << EOF
//      - adminAuth: require
//      EOF
//
const fs = require('fs');
const readline = require('readline');

if (process.argv.length < 3) {
    console.log("\nUsage: node modify-nodered-settings.js <settings.js>");
    process.exit(1);
}

let data_file = process.argv[2];
const cfg = require(data_file);     // require the settings.js file to get the configuration json
let rl = readline.createInterface({input: process.stdin, output: process.stdout});
let data = fs.readFileSync(data_file, 'utf8');

function escapeRegExp(str) {
    return str.replace(/[\-\/\(\)\?\.\\\^\$\|]/g, "\\$&");
}

function matchFrom(d, pattern, from = 0) {
    let idx = from;
    let leng = lines.length;
    for (; idx < leng; idx++) {
        if (d[idx].match(escapeRegExp(pattern))) {
            break;
        }
    }
    return idx;
}

let newData = [];
let target = '';
let endTarget;
let targetValue;
let remove = false;
rl.on('line', data => {
    newData.push(data);
    if (newData.length === 1) {
        if (data.trim()[0] === '-') {
            remove = true;
            data = data.slice(1).trim();
        }
        let tvalue = data.split(':')[1];
        let tvalue_loc = tvalue.search(/\S/);
        target = data.split(':')[0];
        if (tvalue[tvalue_loc] === 'r') {
            targetValue = 'r';
            endTarget = '}),';
        } else {
            targetValue = '{';
            endTarget = '},';
        }
    }
});

rl.on('close', function() {
    lines = data.split('\n');
    let loc = 0;
    let out = 0;
    let end = 0;
    let indentSpaces = 4;
    if (cfg.hasOwnProperty(target)) {
        out = matchFrom(lines, `[ \t]+${target}:[ ]*${targetValue}`)  // target: require => endTarget is '}),'
                                                    // ie. http: { or adminAuth: { or adminAuth: require 
        if (out > 0 && out < lines.length) {
            indentSpaces = lines[out].search(/\S/);
            end = matchFrom(lines, `[ \t]+${endTarget}`, out);
            if (end >= lines.length) {
                console.log(`Error: block for ${target} and ${endTarget} not found in the file.`);
                process.exit(1);
            }
            lines.splice(out, end - out + 1);
        }
        loc = out;
    } else if (!remove) {
        out = matchFrom(lines, `[ \t]+\/\/${target}:[ ]*${targetValue}`)  // target: require => endTarget is '}),'
        if (out < lines.length) {
            indentSpaces = lines[out].search(/\S/);
            end = matchFrom(lines, `[ \t]+\/\/${endTarget}`, out);
            if (end >= lines.length) {
                console.log(`Warning: comment block for ${target} and ${endTarget} not found in the file. \nSo it will be added at the end of the file.`);
                end = lines.length - 3;
            }
        } else {
            console.log(`Warning: comment block for ${target} and ${endTarget} not found in the file. \nSo it will be added at the end of the file.`);
            end = lines.length - 3;
        }
        loc = end + 1;
    }
    if (!remove) {
        let addLines = '';
        for (let l of newData) {
            addLines += " ".repeat(indentSpaces) + l + '\n';
        }
        addLines = addLines.slice(0, -1);

        lines.splice(loc, 0, addLines);
    }
    fs.writeFileSync(data_file, lines.join('\n'));
});
