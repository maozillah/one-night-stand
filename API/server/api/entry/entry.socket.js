/**
 * Broadcast updates to client when the model changes
 */

'use strict';

var Entry = require('./entry.model');

exports.register = function(socket) {
  Entry.schema.post('save', function (doc) {
    onSave(socket, doc);
  });
  Entry.schema.post('remove', function (doc) {
    onRemove(socket, doc);
  });
}

function onSave(socket, doc, cb) {
  socket.emit('entry:save', doc);
}

function onRemove(socket, doc, cb) {
  socket.emit('entry:remove', doc);
}