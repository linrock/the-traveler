var exports = module.exports = {};

var jsdom = require('jsdom');
var fs = require('fs');
var u = require('url');

var jquery = fs.readFileSync('./jquery-2.1.4.js', 'utf-8');


exports.getAbsoluteFaviconUrl = function(url, path) {
  if (path.startsWith('http')) {
    return path;
  } else if (!path.startsWith(url)) {
    if (path.startsWith('//')) {
      return u.parse(url, true).protocol + path;
    } else if (path.startsWith("/")) {
      return url + path;
    } else {
      return url + "/" + path;
    }
  }
  return path;
};


exports.getFaviconLinkFromHTML = function(html) {

  var selectors = [
    'link[rel="shortcut icon"]',
    'link[rel="icon"]',
    'link[type="image/x-icon"]',
    'link[rel="fluid-icon"]',
    'link[rel="apple-touch-icon"]'
  ];

  return new Promise(function(resolve, reject) {
    jsdom.env({
      html: html,
      src: [jquery],
      done: function(err, window) {
        if (err) {
          console.log("Error parsing HTML");
          console.log(err);
          reject(err);
          return;
        }
        var $ = window.$;
        var results = $(selectors.join(','));
        if (results.length > 0) {
          resolve(results.first().attr('href'));
        } else {
          reject({ error: "No favicon links found in HTML" });
        }
      }
    });
  });

};
