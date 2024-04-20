const fs = require('fs');

let data_file = process.argv[2];
const cfg = require(data_file);
/*
    //adminAuth: 
    //https:
    //httpNodeAuth:
*/
let data = fs.readFileSync(data_file, 'utf8');

dd = data.split('\n');

function matchFrom(d, pattern, from = 0) {
    let idx = from;
    let leng = dd.length;
    for (; idx < leng; idx++) {
        if (d[idx].match(pattern)) {
            break;
        }
    }
    return idx;
}
let out = matchFrom(dd, '\/\/adminAuth:')
let end = matchFrom(dd, '\/\/},', out);

let buffer = [];
for (let i = out; i <= end; i++) {
    buffer[i - out] = dd[i].replace(/\/\//, '');
    if (buffer[i - out].match(/\/\/password:/)) {
        buffer[i - out] = dd[i].replace(/password: \"[.]*\"/, /password: \"asdfasf\"/);
    }
}
console.log(buffer.join('\n'));

/*
dd.splice(end + 1, 0, ['adfasdf', 'asdfasdf', '']);
console.log (dd.join('\n'));
*/
