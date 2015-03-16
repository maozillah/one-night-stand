'use strict';

var _ = require('lodash');
var Entry = require('./entry.model');
var fs = require('fs.extra');
var twitterAPI = require('node-twitter-api');
var config = require('../../config/environment');
var request = require('request');
var FormData = require('form-data');
var utf8 = require('utf8');
var twitter_update_with_media = require('./twitter_update_with_media');

var tuwm = new twitter_update_with_media({
  consumer_key: 'ssJE4pQf59uUUClnOOxbcVY3Z',
  consumer_secret: 'sYMIueOvH1KJzZsvh4ByTRrFLrAlwp3BbBuIdAdLssxVnGNz7d',
  token: '2778905934-ZF8N0dEJhPGgBwDuXtzfMtvOepdq9cXFPqMAOiw',
  token_secret: '6JbggFbOmxnD5nEd251NR7HFLexaE3g8iJ4bd1oAEFyaO'
});

var envPath = (config.env === 'production') ? './public/uploads/' : 'client/uploads/';

// Get list of entrys
exports.index = function (req, res) {

  if (req.query.booth) {
    if (req.query.booth === '1') {
      var oppositeBooth = '2';
    } else {
      var oppositeBooth = '1';
    }
  } else {
    var oppositeBooth = '2';
  }

  Entry.findOne({used: false, booth: oppositeBooth}).sort({timestamp: -1}).exec(
    function (err, entrys) {
      if (err) {
        return handleError(res, err);
      }
      if (entrys !== null) {
        toggleEntryUsed(entrys);
        return res.json(200, entrys);
      } else {
        console.log('triggerd failsafe');
        return failsafe(req, res);
      }
    }
  );
};

// Creates a new entry in the DB.
exports.create = function (req, res) {

  var arrayOfFileNames = [];

  if (req.files.sess1) {
    Entry['sess1'] = 'http://104.130.201.159:8080/uploads/' + req.files.sess1.name;
    arrayOfFileNames.push(req.files.sess1.name);
  }
  if (req.files.sess2) {
    Entry['sess2'] = 'http://104.130.201.159:8080/uploads/' + req.files.sess2.name;
    arrayOfFileNames.push(req.files.sess2.name);
  }
  if (req.files.sess3) {
    Entry['sess3'] = 'http://104.130.201.159:8080/uploads/' + req.files.sess3.name;
    arrayOfFileNames.push(req.files.sess3.name);
  }
  if (req.files.sess4) {
    Entry['sess4'] = 'http://104.130.201.159:8080/uploads/' + req.files.sess4.name;
    arrayOfFileNames.push(req.files.sess4.name);
  }
  if (req.files.intro) {
    arrayOfFileNames.push(req.files.intro.name);
  }
  if (req.files.strip) {
    arrayOfFileNames.push(req.files.strip.name);
  }


  // moving the files
  arrayOfFileNames.forEach(function (key) {

    fs.move('uploads/' + key, envPath + key, function (err) {
      if (err) throw err;
    });

  });

  if (req.files.intro) {
    Entry.intro = 'http://104.130.201.159:8080/uploads/' + req.files.intro.name;
  }
  if (req.files.strip) {
    Entry.strip = 'http://104.130.201.159:8080/uploads/' + req.files.strip.name;
  }
  Entry.booth = (req.body.booth) ? parseInt(req.body.booth) : 1;
  Entry.used = false;
  Entry.tweeted = false;

  Entry.create(Entry, function (err, entry) {
    if (err) {
      return handleError(res, err);
    }

    if (req.body.tweet == '1') {
      tuwm.post('Memories of my one night stand at Scotia Bank Nuit Blanche 2014', envPath + req.files.strip.name, function (err, response) {
        if (err) {
          console.log(err);
        }
        console.log('Tweeted this!');
      });
    }

    console.log('success');
    return res.json(201, entry);

  });
};

// Get a single entry
exports.show = function (req, res) {
  Entry.findAll(function (err, entrys) {
    if (err) {
      console.log(err);
      return handleError(res, err);
    }
    return res.json(200, entrys);
  });
};


// Updates an existing entry in the DB.
exports.tweet = function (req, res) {

  if (req.body._id) {
    delete req.body._id;
  }
  Entry.findById(req.params.id, function (err, entry) {
    if (err) return handleError(res, err);
    if (!entry) return res.send(404);

    var fileName = entry.strip.replace(/^.*[\\\/]/, '')
    tuwm.post('Memories of my one night stand at Scotia Bank Nuit Blanche 2014', envPath + fileName, function (err, response) {
      if (err) return handleError(res, err);
      req.body.tweeted = true; // setting the flag to have been tweeted
      var updated = _.merge(entry, req.body);
      updated.save(function (err) {
        if (err) {
          return handleError(res, err);
        }
        console.log('Tweeted this!');
        return res.json(200, entry);
      });

    });
  });
};


// Updates an existing entry in the DB.
exports.update = function (req, res) {
  if (req.body._id) {
    delete req.body._id;
  }
  Entry.findById(req.params.id, function (err, entry) {
    if (err) {
      return handleError(res, err);
    }
    if (!entry) {
      return res.send(404);
    }
    var updated = _.merge(entry, req.body);
    updated.save(function (err) {
      if (err) {
        return handleError(res, err);
      }
      return res.json(200, entry);
    });
  });
};

// Deletes a entry from the DB.
exports.destroy = function (req, res) {
  Entry.findById(req.params.id, function (err, entry) {
    if (err) {
      return handleError(res, err);
    }
    if (!entry) {
      return res.send(404);
    }
    entry.remove(function (err) {
      if (err) {
        return handleError(res, err);
      }
      return res.send(204);
    });
  });
};

// Get list of entrys
exports.all = function (req, res) {
  console.log('here');
  Entry.find(function (err, entrys) {
    if (err) {
      console.log(err);
      return handleError(res, err);
    }
    return res.json(200, entrys);
  });
};


function handleError(res, err) {
  return res.send(500, err);
};


function failsafe(req, res) {

  if (req.query.booth) {
    if (req.query.booth === '1') {
      var oppositeBooth = '2';
    } else {
      var oppositeBooth = '1';
    }
  } else {
    var oppositeBooth = '2';
  }

  Entry.findOne({booth: oppositeBooth}).sort({timestamp: -1}).exec(
    function (err, entrys) {
      if (err) {
        return handleError(res, err);
      }
      return res.json(200, entrys);
    }
  );

};

function toggleEntryUsed(req) {
  Entry.findById(req._id, function (err, entry) {
    if (err) {
      console.log('error updating');
//			return handleError(res, err);
    }
    if (!entry) {
//			return res.send(404);
    }
    var updated = _.merge(entry, req);
    updated.used = true;

    updated.save(function (err) {
      if (err) {
        console.log('error updating');
//				return handleError(res, err);
      }
//			return res.json(200, entry);
    });
  });

};

function GetFilename(url) {
   if (url)
   {
      var m = url.toString().match(/.*\/(.+?)\./);
      if (m && m.length > 1)
      {
         return m[1];
      }
   }
   return "";
};
