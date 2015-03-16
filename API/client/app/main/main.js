'use strict';

angular.module('nuitNormativeApp')
  .config(function ($stateProvider) {
    $stateProvider
      .state('main', {
        url: '/admin',
        templateUrl: 'app/main/main.html',
        controller: 'MainCtrl'
        ,resolve: {
          resolveData: function(EntryService) {
            var data = EntryService.all();
            return data.$promise;
          }
        }
      });
  });
