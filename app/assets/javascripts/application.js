// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require underscore-1.8.3
//= require rsvp-3.1.0
//= require react
//= require react_ujs
//= require components
//= require_tree .


window.Traveler = {};


$(function() {

  var $d = $(document),
      $w = $(window);


  var fetchedIds = {};

  var fetchMoreFavicons = function(last_id) {
    return new RSVP.Promise(function(resolve, reject) {
      if (fetchedIds[last_id]) {
        reject("Already fetched " + last_id);
        return;
      }
      $.ajax({
        url: "/?last_id=" + last_id,
        success: function(data, status, xhr) {
          fetchedIds[last_id] = true;
          resolve(data);
        },
        error: function(xhr, status, error) {
          reject(error);
        }
      });
    });
  };


  var appendFaviconsToList = function(favicons) {
    // console.log(favicons.length);
    var template = _.template(
      '<img class="favicon" src="<%- favicon.favicon_data_uri %>"' +
                           'title="<%- favicon.query_url %>">'
    );
    var html = '';
    _.each(favicons, function(favicon) {
      html += template({ favicon: favicon });
    });
    $(".favicons").append(html);
    return favicons;
  };


  var setLastId = function(favicons) {
    Traveler.last_id = _.last(favicons).id
  };


  var scrollPoller = function() {

    const THRESH = 300,
          T      = 1000;

    var loading = false;

    var shouldScroll = function() {
      return $d.scrollTop() + $w.height() + THRESH >= $d.height();
    };

    var interval = setInterval(function() {
      if (!shouldScroll() || loading) {
        return;
      }
      console.log("should scroll");

      loading = true;

      fetchMoreFavicons(Traveler.last_id)
        .then(appendFaviconsToList)
        .then(setLastId)
        .then(function() {
          console.log("done loading");
          loading = false;
        })
        .catch(function(error) {
          console.log(error);
          loading = false; 
        });

    }, T);

  };

  scrollPoller();

});
