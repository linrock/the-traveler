var exports = module.exports = {};

var fetcher = require('./fetcher.js');
var cache = require('./cache.js');


var normalizedQuery = function(query) {
  if (query.startsWith('http')) {
    return query;
  } else {
    return 'http://' + query;
  }
};


exports.getFaviconFromCache = function(query) {
  return cache.getFavicon(normalizedQuery(query));
};


exports.getFaviconFromSource = function(query) {
  return fetcher.fetchFaviconFromSource(normalizedQuery(query));
};


exports.getFavicon = function(query) {
  var nQuery = normalizedQuery(query);
  return exports.getFaviconFromCache(nQuery)
    .catch(function(error) {
      return exports.getFaviconFromSource(nQuery);
    });
};


exports.getAndWriteFavicon = function(query) {
  var nQuery = normalizedQuery(query);
  return exports.getFaviconFromCache(nQuery)
    .catch(function(error) {
      return exports.getFaviconFromSource(nQuery)
        .then(function(favicon) {
          return cache.writeFavicon(nQuery, favicon)
            .then(function(data) {
              return favicon;
            });
        });
    });
};
