//= require underscore-1.8.3
//= require backbone-1.2.3
//= require rsvp-3.1.0
//= require components
//= require_tree .


window.Traveler = {};


$(function() {

  setTimeout(function() {
    Components.RealTimeUpdater();
    // Components.InfiniteScroller();
  }, 500);

});
