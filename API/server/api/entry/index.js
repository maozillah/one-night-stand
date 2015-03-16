'use strict';

var express = require('express');
var controller = require('./entry.controller');

var router = express.Router();

router.get('/all', controller.all);
router.get('/', controller.index);
router.get('/:id', controller.show);
router.get('/tweet/:id', controller.tweet);
router.post('/', controller.create);
router.put('/:id', controller.update);
router.patch('/:id', controller.update);
router.delete('/:id', controller.destroy);

module.exports = router;
