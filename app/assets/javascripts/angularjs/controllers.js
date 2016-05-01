var phonecatApp = angular.module('StackshareTagAdvisorApp', []);

phonecatApp.controller('TagListCtrl', ['$scope', '$http', function ($scope, $http) {
  $http.get("/tags.json").then(function(response){
    console.log(response.data);
    $scope.tags = response.data;
  });
}]);
