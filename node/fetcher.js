var exports = module.exports = {};

var request = require('request');
var parser = require('./parser.js');

var exec = require('child_process').exec;


exports.test = function() {

  request('http://jsonip.com', function(error, response, body) {

    if (!error && response.statusCode == 200) {
      console.log(body);
    } else {
      console.log(response.statusCode);
      console.log(error);
    }

  });
};


exports.fetchHTMLFromSource = function(query) {

  return new Promise(function(resolve, reject) {

    request(query, function(error, response, body) {
      console.log("Status " + response.statusCode);
      if (!error && response.statusCode == 200) {
        console.log("Fetched HTML for " + query);
        resolve(body);
      } else {
        console.log("Error - " + error);
        console.log("Failed to fetch HTML for " + query);
        reject({ error: error });
      }
    });

  });

};


exports.fetchFaviconDataFromUrl = function(faviconUrl) {
  console.log("Checking " + faviconUrl + " for favicon data");

  return new Promise(function(resolve, reject) {

    // var requestOptions = {
    //   url: faviconUrl,
    //   encoding: null
    // };

    // request(requestOptions, function(error, response, body) {
    //   if (!error && response.statusCode == 200) {
    //     resolve(body);
    //   } else {
    //     reject({ error: error });
    //   }
    // });

    var options = { encoding: 'binary', maxBuffer: 5000 * 1024 };
    exec('curl -sL -m 5 ' + faviconUrl, options, function(error, stdout, stderr) {
      if (error) {
        reject(error);
      } else {
        resolve(new Buffer(stdout, 'binary'));
      }
    });

  });

};


exports.fetchFaviconFromSource = function(query) {

  return exports.fetchHTMLFromSource(query)

    .then(parser.getFaviconLinkFromHTML)
    .then(function(url) {
      return parser.getAbsoluteFaviconUrl(query, url) 
    })
    .catch(function(error) {
      console.log(error);
      console.log("Didn't get favicon URL from HTML: " + query);
      return Promise.resolve(query + "/favicon.ico");
    })
    .then(exports.fetchFaviconDataFromUrl)
    .catch(function(error) {
      console.log(error);
      console.log("Failed to fetch favicon data from url");
    });

};
