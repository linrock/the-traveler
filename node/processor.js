var exports = module.exports = {};

var tmp = require('tmp');
var fs = require('fs');
var exec = require('child_process').exec;


// Returns the path to the tmp file if successful
//
exports.writeDataToTempFile = function(data) {
  return new Promise(function(resolve, reject) {
    tmp.file({ postfix: '.ico' }, function(error, path, fd) {
      fs.writeFile(path, data, 'binary', function(error, written, string) {
        if (error) {
          reject(error);
        } else {
          resolve(path);
        }
      });
    });
  });
};


// returns the mime-type of the data
//
exports.getMimeType = function(data) {
  return new Promise(function(resolve, reject) {
    exports.writeDataToTempFile(data)
      .then(function(filename) {
        var cmd = 'file -b --mime-type ' + filename;
        exec(cmd, function(error, stdout, stderr) {
          if (error) {
            reject(error);
          } else {
            resolve(stdout);
          }
        });
      })
      .catch(function(error) {
        throw error;
      });
  });
};


// returns the output of identify on the data
//
exports.identify = function(data) {
  return new Promise(function(resolve, reject) {
    exports.writeDataToTempFile(data)
      .then(function(filename) {
        var cmd = 'identify ' + filename;
        console.log(cmd);
        exec(cmd, function(error, stdout, stderr) {
          if (error) {
            reject(error);
          } else {
            resolve((stdout + stderr).trim());
          }
        });
      })
      .catch(function(error) {
        throw error;
      });
  });
};


// returns raw PNG data
//
exports.convertToPNG = function(data) {
  return new Promise(function(resolve, reject) {
    exports.writeDataToTempFile(data)
      .then(function(filename) {
        var options = { encoding: 'binary', maxBuffer: 5000 * 1024 };
        var cmd = 'convert -resize 16x16! ' + filename + '[0] png:fd:1';
        exec(cmd, options, function(error, stdout, stderr) {
          if (error || stderr) {
            console.log("Failed to convert to PNG!");
            reject(error || stderr);
          } else {
            resolve(new Buffer(stdout, 'binary'));
          }
        });
      })
  });
};
