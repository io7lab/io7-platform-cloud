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
function matchFrom(d, pattern, from = 0) {
    let idx = from;
    let leng = lines.length;
    for (; idx < leng; idx++) {
        if (d[idx].match(pattern)) {
            break;
        }
    }
    return idx;
}

let newData = [];
let target = '';
let remove = false;
rl.on('line', data => {
    newData.push(data);
    if (newData.length === 1) {
        if (data.trim()[0] === '-') {
            remove = true;
            data = data.slice(1).trim();
        }
        target = data.split(':')[0].trim();
    }
});

rl.on('close', function() {
    lines = data.split('\n');
    let loc = 0;
    let indentSpaces = 0;
    if (cfg.hasOwnProperty(target)) {
        let out = matchFrom(lines, `[ \t]+${target}:[ ]*[r{]`)  // target: { or target: require
                                                                // ie. http: { or adminAuth: { or adminAuth: require 
        if (out > 0) {
            indentSpaces = lines[out].search(/\S/);
            let end = matchFrom(lines, ' },', out);
            lines.splice(out, end - out + 1);
        }
        loc = out;
    } else {
        let out = matchFrom(lines, '[ \t]+\/\/https:[ ]*{')
        let end = lines.length;
        if (out > 0) {
            indentSpaces = lines[out].search(/\S/);
            end = matchFrom(lines, '[ \t]+\/\/},', out);
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
