var http = require('http');

http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('node is on\n');
}).listen(8082);

console.log('Server running on port 8082.');