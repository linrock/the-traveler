var http = require('http');
var url = require('url');

var accessor = require('./accessor.js');
var processor = require('./processor.js');


var requestHandler = function(request, response) {
  var params = url.parse(request.url, true).query;
  var query = params.q;

  if (!query) {
    response.writeHead(404);
    response.end();
    return;
  }

  accessor.getAndWriteFavicon(query)

    .then(function(favicon) {
      processor.getMimeType(favicon).then(console.log);
      return processor.identify(favicon)
        .then(function(identity) {
          // console.log(identity);
          return favicon;
        })
        .catch(function(error) {
          response.writeHead(404, { 'Content-Type' : 'text/plain' });
          response.end('[404] Failed to identify favicon: ' + query + '\n');
          throw error;
        })
        .then(processor.convertToPNG)
        .then(function(data) {
          processor.getMimeType(data).then(function(mimetype) {
            response.writeHead(200, { 'Content-Type' : mimetype });
            response.end(data);
          });
        })
        .catch(function(error) {
          response.writeHead(404, { 'Content-Type' : 'text/plain' });
          response.end('[404] Failed to convert to PNG: ' + query + '\n');
          throw error;
        });
    })

    .catch(function(error) {
      response.writeHead(404, { 'Content-Type' : 'text/plain' });
      response.end('[404] Failed to fetch favicon for: ' + query + '\n');
      console.log(error);
    });

};


var PORT = 8000;
var server = http.createServer(requestHandler);

server.listen(PORT, function() {
  console.log("Server listening on localhost:" + PORT);
});
