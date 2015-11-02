var http = require('http');
var url = require('url');

var accessor = require('./accessor.js');
var processor = require('./processor.js');


var requestHandler = function(request, response) {
  var params = url.parse(request.url, true).query;
  var query = params.q;

  accessor.getFaviconFromSource(query)

    .then(function(favicon) {
      // console.log("Favicon: " + favicon);
      processor.getMimeType(favicon).then(console.log);
      processor.identify(favicon).then(console.log);
      response.end('[200] Found favicon for: ' + query + '\n');
    })

    .catch(function(error) {
      console.log("Error: " + error);
      response.end('[404] Favicon not found for: ' + query + '\n');
    });

};


var server = http.createServer(requestHandler);

server.listen(8000, function() {
  console.log("Server listening on localhost:8000");
});
