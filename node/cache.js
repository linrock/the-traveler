var exports = module.exports = {};

var fs = require('fs');


const CACHE_DIR = "./data/cache/"


var validateData = function(data) {
  return data.status && typeof data === 'object';
};

var serialize = function(data) {
  return JSON.stringify(data);
};

var deserialize = function(data) {
  return JSON.parse(data);
};

var cacheKey = function(query) {
  return CACHE_DIR + encodeURIComponent(query);
}


var writeDataToCache = function(query, data) {
  var filename = cacheKey(query);
  return new Promise(function(resolve, reject) {
    if (validateData(data)) {
      fs.writeFile(filename, serialize(data), function(error) {
        if (error) {
          reject({ error: error });
          return;
        }
        console.log('[200] ' + filename + ' written');
        resolve(data);
      });
    } else {
      reject({ error: 'Invalid data format' });
    }
  });
};


var fetchDataFromCache = function(query) {
  var filename = cacheKey(query);
  return new Promise(function(resolve, reject) {
    console.log(filename);
    fs.stat(filename, function(error, stats) {
      if (error) {
        reject(error);
      } else if (!stats.isFile()) {
        reject({ error: filename + ' is not a file' });
      } else {
        fs.readFile(filename, function(error, serialized) {
          if (error) {
            reject({ error: error });
            return;
          }
          console.log('[200] ' + filename + ' found');
          var data = deserialize(serialized);
          if (validateData(data)) {
            resolve(data);
          } else {
            reject({ error: 'Invalid data format' });
          }
        });
      }
    });
  });
};


exports.getFavicon = function(query) {
  return fetchDataFromCache(query)
    .then(function(data) {
      if (data.favicon) {
        return new Buffer(data.favicon, 'base64');
      } else {
        throw { error: "Favicon not found for " + query };
      }
    });
};


exports.writeFavicon = function(query, faviconData) {
  var data = {
    status: 200,
    favicon: new Buffer(faviconData).toString('base64'),
    expires: Date.now() + 30 * 86400 * 1000
  };
  return writeDataToCache(query, data);
};
