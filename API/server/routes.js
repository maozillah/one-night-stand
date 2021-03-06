/**
 * Main application routes
 */

'use strict';

var errors = require('./components/errors');
var bodyParser = require('body-parser');
var multer = require('multer');

module.exports = function(app) {

	app.use(bodyParser());
	app.use(multer({ dest: './uploads/' }));

	// Insert routes below
  app.use('/api/entrys', require('./api/entry'));

  // All undefined asset or api routes should return a 404
  app.route('/:url(api|auth|components|app|bower_components|assets)/*')
   .get(errors[404]);

  // All other routes should redirect to the index.html
  app.route('/*')
    .get(function(req, res) {
      res.sendfile(app.get('appPath') + '/index.html');
    });
};
