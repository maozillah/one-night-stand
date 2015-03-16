// server.js

// BASE SETUP
// =============================================================================

// call the packages we need
var express    = require('express'); 		// call express
var mongoose   = require('mongoose');
var bodyParser = require('body-parser');
var multer  	 = require('multer');
var fs 				 = require('fs');
var PhotoSet 	 = require('./models/photoset');

var app        = express(); 				// define our app using express

// configure app to use bodyParser()
// this will let us get the data from a POST
app.use(bodyParser());
app.use(multer({ dest: './uploads/' }));

var port = process.env.PORT || 8080; 		// set our port

// ROUTES FOR OUR API
// =============================================================================
var router = express.Router(); 				// get an instance of the express Router

// middleware to use for all requests
router.use(function(req, res, next) {
	// do logging
	next();
});


// get the most recent photoset from booth
router.get('/photos/booth/:booth', function(req, res) {

	if (req.params.booth == '1') {
		PhotoSet.find({$and: [{booth:1}, {used:false}]})
			.limit(1)
		 	.sort({date: 1})
		 	.execFind(function(err, BoothOnePhotoset) {

     	if (err) throw err;

     	// cycle through older photosets if all photosets used RENAME THIS
			if (BoothOnePhotoset.length == 0) {
				PhotoSet.find({$and: [{booth:1}, {used:true}]})
				.limit(1)
			 	.sort({date: 1})
			 	.execFind(function(err, photosets) {
			 		res.json(photosets);
		 		 });
			// otherwise display latest photoset that hasn't been used
			} else { res.json(BoothOnePhotoset); }

	 });

	}else {
		PhotoSet.find({$and: [{booth:2}, {used:false}]})
			.limit(1)
		 	.sort({date: 1})
		 	.execFind(function(err, BoothTwoPhotoset) {

     	if (err) throw err;

     	// cycle through older photosets if all photosets used RENAME THIS
			if (BoothTwoPhotoset.length == 0) {
				PhotoSet.find({$and: [{booth:2}, {used:true}]})
				.limit(1)
			 	.sort({date: 1})
			 	.execFind(function(err, photosets) {
			 		res.json(photosets);
		 		 });
			// otherwise display latest photoset that hasn't been used
			} else { res.json(BoothTwoPhotoset); }
	 });
	}
});

/* Toggle photosets to used */
router.post('/used/:id', function(req, res) {
	// id of photoset
   var idUsedPhotoset = req.params.id;

   PhotoSet.findById(idUsedPhotoset, function(err, usedPhotos) {
       if (err)
		res.send(err);

		// toggle photoset to used		
		usedPhotos.used = !usedPhotos.used;

		usedPhotos.save(function(err, doc) {
				if (err)
					res.send(err);

				// success!
				res.send(200);
			});
    });
});

router.get('/photos/all', function(req, res) {

	PhotoSet.find(function(err, photosets) { //saying PhotoSet = photosets

		if (err) throw err;

		res.json(photosets);

	});
});


// add a photo array
router.post('/photos', function(req, res) {

	var photoSet = new PhotoSet();
	photoSet.booth = req.body.booth; // asking for booth number from processing
	photoSet.date =  Date.now();
	photoSet.used = false;

	var files = [],
		fileKeys = Object.keys(req.files);

	fileKeys.forEach(function(key) {
		photoSet.files.push('uploads/'+req.body.booth+'/'+req.files[key].name);

	//copy and place in folder
		fs.rename(req.files[key].path, './uploads/' + req.body.booth + '/' + req.files[key].name, function(err) {
        if (err) throw err;

		
        // delete the temporary file, so that the explicitly set temporary upload dir does not get filled with unwanted files
        fs.unlink(req.files[key].path, function() {
          if (err) throw err;
        });
    });
	});

	photoSet.save(function(err) {
		if (err) {
			res.send(err);
		}

		res.json({ 'message': 'yes!' });
	});

});

// test route to make sure everything is working (accessed at GET http://localhost:8080/api)
router.get('/', function(req, res) {
	res.json({ message: 'hooray! welcome to our api!' });
});

// more routes for our API will happen here

// REGISTER OUR ROUTES -------------------------------
// all of our routes will be prefixed with /api
app.use('/api', router);

// START THE SERVER
// =============================================================================
app.listen(port);
console.log('Magic happens on port ' + port);
