var http = require('http');

var port = undefined;

process.argv.forEach(function(f) {
  var m = f.match(/--http_port=(\d+)/);
  if (m) {
    port = m[1];
  }
});

http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello World\n');
}).listen(port);
console.log('HTTP server running on port : ' + port);