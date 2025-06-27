var redis   = require('redis');

const rClient = redis.createClient({url:'redis://127.0.0.1:6379'});
rClient.on('error', (err) => console.log('Redis Client Error', err));
rClient.connect();

var obj = process.argv[2];
var newValue = process.argv[3];
if (obj === '-h' || obj === undefined) {
    console.log('Usage : node ' + process.argv[1] + ' deviceName  value');
    rClient.quit();
} else {
	(async () => {
		var value = await rClient.get(obj) || 'None';
        console.log('Removing(' +obj+ ') : ' + JSON.stringify(value));
        await rClient.del(obj);
        rClient.quit();
	})();
}
