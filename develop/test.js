const { parse, stringify } = require('yaml')
const fs = require('fs');

let data = fs.readFileSync(process.argv[2], 'utf8');
let jo = parse(data)

fs.writeFileSync('aa.json', JSON.stringify(jo, null, 4))
fs.writeFileSync('bb.yml', stringify(jo))
