var exports = module.exports = {};

var cacheDir = "./data/cache/"


exports.fetchFromCache = function(query) {
  var filename = cacheDir + query;
  return new Promise(function(resolve, reject) {
    if (fs.exists(filename)) {
      fs.readFile(filename, function(error, data) {
        if (error) {
          reject({ error: error });
        }
        console.log('[200] ' + filename + ' found');
        resolve(data);
      });
    } else {
      reject({ error: 'Not found' });
    }
  });
};


exports.writeToCache = function(query, data) {
  var filename = cacheDir + query;
  return new Promise(function(resolve, reject) {
    fs.writeFile(filename, data, function(error) {
      if (error) {
        reject({ error: error });
      }
      console.log('[200] ' + filename + ' written');
      resolve(data);
    });
  });
};
