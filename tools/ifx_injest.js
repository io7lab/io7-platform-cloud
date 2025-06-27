// influxdb testing 
// replace the token
const http = require('http');

const data = 'alldevices,device=server01 temperature=23.6';
const influxdb_token = 'Sy4TNf6ba77R3M5Kd5l5UZUV_0q4CNZBlG09G578-J7Pwe_aVc0w3wE8jHoq9eUh156BZELMm4_4fN9dV3I5Lw==';

const req = http.request({
    hostname: 'localhost',
    port: 8086,
    path: '/write?db=bucket01',
    method: 'POST',
    headers: {
      'Authorization': `Token ${influxdb_token}`,
      'Content-Type': 'text/plain',
      'Content-Length': data.length
    }
},
res => {
    console.log(res.statusCode);
    res.on('data', chunk => console.log(chunk.toString()));
});

req.on('error', e => console.error(e));
req.end(data);