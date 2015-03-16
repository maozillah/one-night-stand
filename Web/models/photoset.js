// app/mdoels/photo.js

var mongoose = require('mongoose');
var Schema = mongoose.Schema;

var PhotoSetSchema = new Schema({
  booth: Number,
  date: Date,
  used: Boolean,
  files: Array
});

module.exports = mongoose.model('PhotoSet', PhotoSetSchema);

mongoose.connect('mongodb://@localhost:27017/nuit-blanche');
