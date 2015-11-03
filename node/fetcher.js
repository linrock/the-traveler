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

    request(query, { gzip: true, timeout: 8000 }, function(error, response, body) {
      if (!response) {
        console.log(query + " - No response!");
        reject({ error: error });
        return;
      }
      console.log(query + " - status " + response.statusCode);
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
  return new Promise(function(resolve, reject) {
    if (!faviconUrl) {
      var error = { error: "No favicon url given" };
      reject(error);
      throw error;
    }
    console.log("Checking " + faviconUrl + " for favicon data");

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
    var cmd = 'curl -sL -m 5 --compressed --fail --show-error ' + faviconUrl;
    exec(cmd, options, function(error, stdout, stderr) {
      if (error || stderr) {
        reject(error || stderr);
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
    .then(exports.fetchFaviconDataFromUrl)
    .catch(function(error) {
      console.log("Didn't get favicon URL from HTML: " + query);
      return Promise.resolve(query + "/favicon.ico")
        .then(exports.fetchFaviconDataFromUrl)
        .catch(function(error) {
          console.log("Failed to fetch favicon data for " + query);
          throw error;
        });
    });

};
