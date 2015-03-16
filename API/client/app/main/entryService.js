'use strict';

angular.module('nuitNormativeApp')
  .factory('EntryService', function ($resource) {
    return $resource('/api/entrys/:id', {
      id: '@id'
    }, {
      'get': {method: 'GET'},
      'all': {
        method: 'GET',
        url: '/api/entrys/all',
        isArray: true
      },
      'tweet': {
        method: 'GET',
        url: '/api/entrys/tweet/:id'
      },
      'save': {method: 'POST'},
      'update': {method: 'PUT'},
      'delete': {method: 'DELETE'}
    });
	});
