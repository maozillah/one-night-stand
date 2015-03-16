'use strict';

var mongoose = require('mongoose'),
    Schema = mongoose.Schema;

var EntrySchema = new Schema({
	timestamp: {
		type: Date,
		default: Date.now
	},
	booth: Number,
	used: Boolean,
  tweeted: Boolean,
	strip: String,
	intro: String,
	sess1: String,
	sess2: String,
	sess3: String,
	sess4: String
});

module.exports = mongoose.model('Entry', EntrySchema);
