'use strict';

angular.module('nuitNormativeApp')
  .controller('MainCtrl', function ($scope, resolveData, EntryService) {
    $scope.data = resolveData;

    $scope.deleteEntry = function(doc) {
      EntryService.delete({id: doc._id}).$promise.
        then(function(data){
          console.log('success delete');
          var index = $scope.data.indexOf(doc);
          if (index !== -1) {
            $scope.data.splice(index, 1);
          }
        });
    };

    $scope.tweetEntry = function(doc) {
      EntryService.tweet({id: doc._id}).$promise.
        then(function(data){
          console.log('success tweet');
          var index = $scope.data.indexOf(doc);
          if (index !== -1) {
            $scope.data[index].tweeted = true;
          }
        })
    };

  });
