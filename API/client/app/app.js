'use strict';

angular.module('nuitNormativeApp', [
  'ngResource',
  'ui.router'
])
  .config(function ($urlRouterProvider, $locationProvider) {
    $urlRouterProvider.otherwise('/');

    $locationProvider.html5Mode(true);
  });
