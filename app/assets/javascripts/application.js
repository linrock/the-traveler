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


  var RecentFaviconFetcher = function() {

    const N_COLS = 5;

    var next_id = Traveler.first_id;
    var last_checked_id = false;
    var favicon_queue = [];

    var startFetcher = function(first_id) {
      return new RSVP.Promise(function(resolve, reject) {
        if (next_id == last_checked_id) {
          reject("Already checked " + next_id);
        } else {
          resolve(first_id);
        }
      });
    };

    var fetchRecentFavicons = function(first_id) {
      console.log("Checking for favicons since " + first_id);
      return new RSVP.Promise(function(resolve, reject) {
        $.ajax({
          url: "/traveler/favicons?after_id=" + first_id,
          dataType: "json",
          success: function(data, status, xhr) {
            var favicons = data.favicons;

            // TODO update traveler status elsewhere
            $(".s").text(data.traveler.status);

            if (favicons.length > 0) {
              next_id = _.first(favicons).id;
              last_checked_id = first_id;
            }
            resolve(favicons);
          },
          error: function(xhr, status, error) {
            reject(error);
          }
        });
      });
    };

    var queueRecentFavicons = function(favicons) {
      favicon_queue = favicon_queue.concat(favicons);
      var n = favicon_queue.length;
      console.log("Adding " + favicons.length + " favicons to queue (" + n + " total)");
    };

    var template = _.template(
      '<img class="favicon invisible"' +
           'src="<%- favicon.favicon_data_uri %>"' +
           'title="<%- favicon.query_url %>">'
    );

    var addFaviconFromQueue = function() {
      var favicon = favicon_queue.shift();
      if (!favicon) {
        return;
      }
      var html = template({ favicon: favicon });
      var $row = $(".favicons .favicon-row").first();
      if ($row.length == 0 || $row.find(".favicon").length == N_COLS) {
        $row = $('<div class="favicon-row">');
        $(".favicons").prepend($row);
        $(".favicons .favicon-row").last().remove();
      }
      var $html = $(html);
      $html.appendTo($row);
      setTimeout(function() {
        $html.removeClass("invisible");
      }, 50);
    };

    var pollForFavicons = function() {
      startFetcher(next_id)
        .then(fetchRecentFavicons)
        .then(queueRecentFavicons)
        .catch(function(error) {
          console.log("Favicon polling error: " + error);
          return true;
        })
        .then(function() {
          setTimeout(pollForFavicons, 5000);
        });
    };

    var periodicallyAddFaviconsFromQueue = function() {
      var delay = ~~ (750 + Math.random() * 500);
      addFaviconFromQueue();
      setTimeout(periodicallyAddFaviconsFromQueue, delay);
    };

    pollForFavicons();
    periodicallyAddFaviconsFromQueue();

  };

  RecentFaviconFetcher();


  var InfiniteScrollFavicons = function() {

    var fetchedIds = {};

    var startFetcher = function(last_id) {
      return new RSVP.Promise(function(resolve, reject) {
        if (fetchedIds[last_id]) {
          reject("Already fetched " + last_id);
        } else {
          // console.log("Fetching since " + last_id);
          resolve(last_id);
        }
      });
    };


    var fetchPastFavicons = function(last_id) {
      return new RSVP.Promise(function(resolve, reject) {
        $.ajax({
          url: "/traveler/favicons?before_id=" + last_id,
          dataType: "json",
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
        '<img class="favicon invisible delay-<%- favicon.anim_delay %>"' +
             'src="<%- favicon.favicon_data_uri %>"' +
             'title="<%- favicon.query_url %>">'
      );
      var html = '<div class="favicon-sheet invisible">';
      var n = favicons.length;
      _.each(favicons, function(favicon, j) {
        favicon.anim_delay = ~~ ( Math.random() * j / n * 10);
        html += template({ favicon: favicon });
      });
      html += '</div>';
      var $html = $(html);
      $html.appendTo($(".favicons"));
      setTimeout(function() {
        $html.removeClass("invisible");
        setTimeout(function() {
          $html.find(".invisible").removeClass("invisible");
        }, 50);
      }, 50);
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
        // console.log("should scroll");

        loading = true;

        startFetcher(Traveler.last_id)
          .then(fetchPastFavicons)
          .then(appendFaviconsToList)
          .then(setLastId)
          .then(function() {
            loading = false;
          })
          .catch(function(error) {
            console.log(error);
            loading = false;
          });

      }, T);

    };

    scrollPoller();

  };

  InfiniteScrollFavicons();

});
