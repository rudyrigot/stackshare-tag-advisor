var phonecatApp = angular.module('StackshareTagAdvisorApp', []);

phonecatApp.controller('TagListCtrl', ['$scope', '$http', function ($scope, $http) {
  $scope.loaded = false;
  $http.get("/tags.json").then(function(response){
    $scope.tags = response.data;
    $scope.loaded = true;
  });
}]);
