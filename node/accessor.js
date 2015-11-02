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
  return cache.fetchFromCache(normalizedQuery(query));
};


exports.getFaviconFromSource = function(query) {
  return fetcher.fetchFaviconFromSource(normalizedQuery(query));
};


exports.getFavicon = function(query) {
  return exports.getFaviconFromCache(normalizedQuery(query))
    
    .then(function(favicon) {
      return favicon;
    })

    .catch(function(error) {
      console.log('error fetching from cache: ' + error);

      return exports.getFaviconFromSource(url)

        .then(function(favicon) {
          console.log('Fetched from source! ' + favicon);
          return 'Sure';
        })

        .catch(function(error) {
          console.log('Nope from source! ' + error);
          throw 'Nope';
        });

    });

};
