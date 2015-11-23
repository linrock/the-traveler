Components.RealTimeUpdater = function() {

  const N_COLS = 5;


  var events = _.clone(Backbone.Events);


  // Favicon queue
  //
  var FaviconQueue = function() {

    var queue = [];

    var size = function() {
      return queue.length;
    };

    return {

      next: function() {
        return queue.shift();
      },

      size: size,

      enqueue: function(favicons) {
        queue = queue.concat(favicons);
        console.log("Adding " + favicons.length + " favicons to queue (" + size() + " total)");
        return queue;
      },

      isFull: function() {
        return size() > 50;
      },

      isEmpty: function() {
        return size() == 0;
      }

    };

  };


  // Neighborhoods - watch for popular domains + subdomains
  //
  var NeighborhoodWatch = function() {

    events.on("neighborhood:check", function() {
      var urls = _.map($(".favicon-row .favicon"), function(f) {
        return $(f).attr("title");
      });
      var domains = _.map(urls, function(url) {
        var sections = url.split(".");
        if (sections.length == 3) {
          return sections.slice(1).join(".");
        } else if (sections.length == 4) {
          return sections.slice(2).join(".");
        }
      });
      var domains = _.select(domains);
      var counts = {};
      for (var i = domains.length-1; i > 0; i--) {
        var domain = domains[i];
        counts[domain] = counts[domain] || 0;
        counts[domain]++;
      }
      var max = 0;
      var popular = false;
      _.forEach(counts, function(count, domain) {
        if (count > max) {
          popular = domain;
          max = count;
        }
      });
      console.dir(counts);
      console.log(popular + " " + max);
      if (max > 30) {
        events.trigger("neighborhood:visiting", popular);
      } else {
        events.trigger("neighborhood:visiting", false);
      }
    });

    events.on("neighborhood:visiting", function(domain) {
      if (domain) {
        $(".neighborhood").text("Passing through " + domain).removeClass("invisible");
      } else {
        $(".neighborhood").addClass("invisible");
      }
    });

  };


  // Fetch favicons periodically, manage traveler status
  //
  var FaviconContentUpdater = function() {

    var next_id = Traveler.latest_id;
    var last_checked_id = false;

    var startFetcher = function(latest_id) {
      return new RSVP.Promise(function(resolve, reject) {
        if (next_id == last_checked_id) {
          reject("Already checked " + next_id);
        } else if (favicon_queue.isFull()) {
          reject("Queue is pretty full - " + favicon_queue.size());
        } else {
          resolve(latest_id);
        }
      });
    };

    var updateTravelerStatus = function(status) {
      if (!$(".status-icon").hasClass(status)) {
        $(".status-icon").removeClass()
          .addClass("status-icon " + status)
          .attr("title", "Status - " + status);
      }
    };

    var fetchRecentFavicons = function(latest_id) {
      console.log("Checking for favicons since " + latest_id);
      return new RSVP.Promise(function(resolve, reject) {
        $.ajax({
          url: "/the-traveler/updates?after_id=" + latest_id,
          dataType: "json",
          success: function(data, status, xhr) {
            var favicons = data.favicons;
            var status = data.traveler.status;
            updateTravelerStatus(status);
            if (favicons.length > 0) {
              next_id = _.max([ _.first(favicons).id, _.last(favicons).id ]);
              last_checked_id = latest_id;
              events.trigger("neighborhood:check");
            }
            resolve(favicons);
          },
          error: function(xhr, status, error) {
            reject(error);
          }
        });
      });
    };

    var pollForFavicons = function() {
      startFetcher(next_id)
        .then(fetchRecentFavicons)
        .then(favicon_queue.enqueue)
        .catch(function(error) {
          console.log("Favicon polling error: " + error);
          return true;
        })
        .then(function() {
          setTimeout(pollForFavicons, 5000);
        });
    };

    return {
      run: pollForFavicons
    };

  };


  // New animator that also moves the traveler
  //
  var FaviconSheetAnimator = function() {

    var i = Traveler.i,
        direction = Traveler.direction;

    var $sheet = $(".favicons .favicon-sheet"),
        $traveler = $(".the-traveler");

    var faviconTemplate = _.template(
      '<img class="favicon invisible"' +
           'src="<%- favicon.favicon_data_uri %>"' +
           'title="<%- favicon.query_url %>">'
    );

    var checkFaviconQueue = function() {
      return new RSVP.Promise(function(resolve, reject) {
        if (!favicon_queue.isEmpty()) {
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
        } else if (i === N_COLS - 1) {
          direction = -1;
        }
        return animateSheet();
      }
      i = i + direction;
      if (i === 0 || i === N_COLS - 1) {
        direction = 0;
      }
      return animateTraveler();
    };

    var animateSheet = function() {

      var $createRow = function() {
        if (direction == 1) {
          polarity = 'left';
        } else {
          polarity = 'right';
        };
        return $('<div>').addClass("favicon-row " + polarity);
      };

      var $initIllusion = function($sheet) {
        var $illusion = $sheet.clone().addClass("illusion");
        return new RSVP.Promise(function(resolve, reject) {
          setTimeout(function() {
            resolve($illusion);
          }, 5);
        });
      };

      var animateIllusion = function($illusion) {
        return new RSVP.Promise(function(resolve, reject) {
          $sheet.prepend($createRow());
          var $rows = $sheet.find(".favicon-row");
          var maxRowsReached = $rows.length > Traveler.max_rows;
          if (maxRowsReached) {
            $rows.last().remove();
          }
          $illusion.appendTo($(".favicons"));
          setTimeout(function() {
            $illusion.addClass("anim");
            if (maxRowsReached) {
              $illusion.find(".favicon-row").last().addClass("invisible");
            }
            setTimeout(function() {
              $illusion.remove();
              resolve();
            }, 250);
          }, 10);
        });
      };

      return $initIllusion($sheet).then(animateIllusion);
    };

    var animateTraveler = function() {
      var x = i * 30;
      $traveler.css({ "transform" : "translate3d(" + x + "px,0,0)" });
      return new RSVP.Promise(function(resolve, reject) {
        setTimeout(function() {
          resolve();
        }, 250);
      });
    };

    var showFavicon = function() {
      var $favicon = $(faviconTemplate({ favicon: favicon_queue.next() }));
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
      // TODO lower delay for larger queue sizes
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

    var initAndRun = function() {
      $traveler
        .removeClass("invisible")
        .css({ "transform" : "translate3d(" + Traveler.i * 30 + "px,0,0)" });
      $sheet.removeClass("invisible");
      setTimeout(function() {
        run();
      }, 500);
    };

    return {
      run: initAndRun
    };

  };


  // init
  //
  var favicon_queue = FaviconQueue();
  FaviconContentUpdater().run();
  FaviconSheetAnimator().run();
  NeighborhoodWatch();

};
