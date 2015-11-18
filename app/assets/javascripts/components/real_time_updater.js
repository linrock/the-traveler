Components.RealTimeUpdater = function() {


  // Favicon fetcher
  //
  var next_id = Traveler.first_id;
  var last_checked_id = false;

  var startFetcher = function(first_id) {
    return new RSVP.Promise(function(resolve, reject) {
      // TODO reject if queue is too full
      if (next_id == last_checked_id) {
        reject("Already checked " + next_id);
      } else if (favicon_queue.length > 50) {
        reject("Queue is pretty full - " + favicon_queue.length);
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
          var status = data.traveler.status;

          // TODO update traveler status elsewhere
          if (!$(".status-icon").hasClass(status)) {
            $(".status-icon").removeClass()
              .addClass("status-icon " + status)
              .attr("title", "Status - " + status);
          }

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


  // Favicon renderer
  //
  const N_COLS = 5;

  var template = _.template(
    '<img class="favicon invisible"' +
         'src="<%- favicon.favicon_data_uri %>"' +
         'title="<%- favicon.query_url %>">'
  );

  var faviconRowHandler = (function() {
    var polarity = 'right';

    var $firstRow = function() {
      return $(".favicons .favicon-row").first();
    };

    var $createRow = function() {
      if (polarity == 'left') {
        polarity = 'right';
      } else {
        polarity = 'left';
      };
      return $('<div>').addClass("favicon-row " + polarity);
    };

    var $topRow = function() {
      var $row = $firstRow();
      if ($row.length == 0 || $row.find(".favicon").length == N_COLS) {
        $row = $createRow();
        $(".favicons .favicon-sheet").prepend($row);
        animateFaviconIllusion().then(hideFaviconIllusion);
        removeLastFaviconRow();
      }
      return $row;
    };

    return {
      $topRow: $topRow
    };

  })();


  // Favicon sheet-sliding illusion when prepending favicons
  //
  var animateFaviconIllusion = function() {
    return new RSVP.Promise(function(resolve, reject) {
      var $sheet = $(".favicons .favicon-sheet");
      var $illusion = $sheet.clone().addClass("illusion");
      $illusion.appendTo($(".favicons"));
      setTimeout(function() {
        $illusion.addClass("anim");
        $illusion.find(".favicon-row").last().addClass("invisible");
        setTimeout(function() {
          resolve($illusion);
        }, 250);
      }, 10);
    });
  };

  var hideFaviconIllusion = function($illusion) {
    $illusion.remove();
  };

  var removeLastFaviconRow = function() {
    $(".favicons .favicon-sheet:not(.illusion) .favicon-row").last().remove();

  };

  // Favicon queue
  //
  var favicon_queue = [];

  var queueRecentFavicons = function(favicons) {
    favicon_queue = favicon_queue.concat(favicons);
    var n = favicon_queue.length;
    console.log("Adding " + favicons.length + " favicons to queue (" + n + " total)");
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

  var addFaviconFromQueue = function() {
    var favicon = favicon_queue.shift();
    if (!favicon) {
      return;
    }
    var $favicon = $(template({ favicon: favicon }));

    prepareToAddFavicon()
      .then();

    $favicon.appendTo(faviconRowHandler.$topRow());
    setTimeout(function() {
      $favicon.removeClass("invisible");
    }, 50);
  };

  var periodicallyAddFaviconsFromQueue = function() {
    // TODO lower delay for larger queue sizes
    var delay = ~~ (500 + Math.random() * 500);
    addFaviconFromQueue();
    setTimeout(periodicallyAddFaviconsFromQueue, delay);
  };


  // New animator that moves the traveler
  //
  var TravelerAnimator = function() {

    var i = 0;
    var direction = 0;
    var $sheet = $(".favicons .favicon-sheet");

    var checkFaviconQueue = function() {
      return new RSVP.Promise(function(resolve, reject) {
        if (favicon_queue.length > 0) {
          resolve();
        } else {
          reject({ error: "No favicon in queue" });
        }
      });
    };

    var decideAnimation = function() {
      if (direction === 0) {
        if (i === 0) {
          direction = 1;
        } else if (i === 4) {
          direction = -1;
        }
        return animateSheet();
      }
      i = i + direction;
      if (i === 0 || i === 4) {
        direction = 0;
      }
      return animateTraveler();
    };

    var animateSheet = function() {
      // console.log("Animating sheet");

      var $createRow = function() {
        if (direction == 1) {
          polarity = 'left';
        } else {
          polarity = 'right';
        };
        return $('<div>').addClass("favicon-row " + polarity);
      };

      return new RSVP.Promise(function(resolve, reject) {
        var $illusion = $sheet.clone().addClass("illusion");
        $sheet.prepend($createRow());
        $sheet.find(".favicon-row").last().remove();
        $illusion.appendTo($(".favicons"));
        setTimeout(function() {
          $illusion.addClass("anim");
          $illusion.find(".favicon-row").last().addClass("invisible");
          setTimeout(function() {
            $illusion.remove();
            resolve();
          }, 250);
        }, 10);
      });
    };

    var animateTraveler = function() {
      var $traveler = $(".the-traveler");
      // console.log("animating traveler - " + "i: " + i + ", direction: " + direction);
      var x = i * 30;
      $traveler.css({ "transform" : "translate3d(" + x + "px,0,0)" });
      return new RSVP.Promise(function(resolve, reject) {
        setTimeout(function() {
          resolve();
        }, 250);
      });
    };

    var showFavicon = function() {
      var $favicon = $(template({ favicon: favicon_queue.shift() }));
      return new RSVP.Promise(function(resolve, reject) {
        $favicon.appendTo($sheet.find(".favicon-row").first());
        setTimeout(function() {
          $favicon.removeClass("invisible");
          setTimeout(function() {
            resolve();
          }, 750);
        }, 25);
      });
    };

    var delayedRun = function() {
      var delay = ~~ (400 + Math.random() * 500);
      setTimeout(run, delay);
    };

    var run = function() {
      checkFaviconQueue()
        .then(decideAnimation)
        .then(showFavicon)
        .catch(function(error) {
          // console.log(error);
        })
        .then(delayedRun)
    };

    return {
      run: run
    };

  };


  // init
  //
  pollForFavicons();
  // periodicallyAddFaviconsFromQueue();
  TravelerAnimator().run();

};
