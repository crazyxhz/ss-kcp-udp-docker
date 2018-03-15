const fs = require('fs');
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const port = process.env.PORT || 1986;
const ip = process.env.SOCKSERVER_IP || 'localhost';
const socks_port = process.env.SOCKSERVER_PORT || '5544';
const router = express.Router();
const url = require('url');

app.use(bodyParser.urlencoded({extended: true}));
// app.use(bodyParser.json());
app.use(bodyParser.text());
app.use(function (req, res, next) {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
});

let domains = {}, result;

const pacFile = 'pac/paclist';

function generateDomainsList () {
  domains = {};
  const rl = require('readline').createInterface({
    input: fs.createReadStream(pacFile)
  });
  rl.on('line', (line) => {
    domains[line] = 1;
  });
  rl.on('close', () => {
    result = `var domains = ${JSON.stringify(domains)};function FindProxyForURL(a,b){var c;do{if(domains.hasOwnProperty(b))return domains[b]?proxy:direct;c=b.indexOf(".")+1,b=b.slice(c)}while(c>1);return direct}var proxy="SOCKS5 ${ip}:${socks_port};",direct="DIRECT;";`;
  });
}

generateDomainsList();

fs.watch('.', (eventType, filename) => {
  if (filename === pacFile) {
    console.log(`File changed: ${filename}`);
    generateDomainsList();
  }
});

router.get('/', function (req, res) {
  res.setHeader('content-type', 'application/x-ns-proxy-autoconfig');
  res.send(result);
});
app.post('/add', function (req, res) {
  let parsed = url.parse(req.body);
  if (!parsed.hostname) {
    res.send({error: 'URL解析失败'});
    return;
  }
  let host = parsed.hostname.split('.');
  let result = [];
  result.unshift(host.pop());
  result.unshift(host.pop());
  result = result.join('.') + '\n';
  fs.appendFile(pacFile, result, function (err) {
    if (err) throw err;
    console.log(`Saved! ${result}`);
  });
  res.json({result});
});
app.post('/del', function (req, res) {
  let index = req.body;
  if (Number.isNaN(index)) {
    res.send({error: '参数非法'});
    return;
  }
  fs.readFile(pacFile, 'utf8', function (err, data) {
    if (err) {
      if (err) throw err;
    }
    let lines = data.split('\n');
    lines.splice(index, 1);

    fs.writeFile(pacFile, lines.join('\n'), function () {
      res.send({success: true});
    });

  });
});
app.get('/list', function (req, res) {
  fs.readFile(pacFile, 'utf8', function (err, data) {
    if (err) throw err;
    res.send(data);
  });
});
app.use('/pac', router);
app.use(express.static(__dirname + '/public'));
app.listen(port);
console.log('Listening on port ' + port);
