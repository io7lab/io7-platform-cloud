var redis   = require('redis');

const rClient = redis.createClient({url:'redis://127.0.0.1:6379'});
rClient.on('error', (err) => console.log('Redis Client Error', err));
rClient.connect();

var qStr = process.argv[2] || '*';
if (qStr === '-h') {
    console.log('Usage : node ' + process.argv[1] + '[device name]');
    rClient.quit();
} else {
    (async () => {
        const keys = await rClient.keys(qStr);
        for (k of keys) {
            var value = await rClient.get(k);
            if (value.match(/^\{.*\}/)) {
                let objState = JSON.parse(value);
                if (objState.hasOwnProperty('t')) {
                    objState.t = (new Date(objState.t)).toLocaleString();
                    //console.log((`${k}(${(new Date(objState.t)).toLocaleString()})`).padEnd(28) + ' : ' + value);
                    value = JSON.stringify(objState);
                }
            }
            console.log((`${k}`).padEnd(28) + ' : ' + value);
        }
        rClient.quit();
	})();
}

