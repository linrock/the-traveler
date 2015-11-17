Components.RealTimeUpdater = function() {


  // Favicon fetcher
  //
  var next_id = Traveler.first_id;
  var last_checked_id = false;

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

    var $createRow = function() {
      if (polarity == 'left') {
        polarity = 'right';
      } else {
        polarity = 'left';
      };
      return $('<div>').addClass("favicon-row " + polarity);
    };

    var $topRow = function() {
      var $row = $(".favicons .favicon-row").first();
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

  var animateFaviconSheet = function() {
    return animateFaviconIllusion().then(hideFaviconIllusion);
  };

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

  window.animateFaviconSheet = animateFaviconSheet;


  // Favicon queue
  //
  var favicon_queue = [];

  var queueRecentFavicons = function(favicons) {
    favicon_queue = favicon_queue.concat(favicons);
    var n = favicon_queue.length;
    console.log("Adding " + favicons.length + " favicons to queue (" + n + " total)");
  };

  var addFaviconFromQueue = function() {
    var favicon = favicon_queue.shift();
    if (!favicon) {
      return;
    }
    var $favicon = $(template({ favicon: favicon }));
    $favicon.appendTo(faviconRowHandler.$topRow());
    setTimeout(function() {
      $favicon.removeClass("invisible");
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


  // init
  //
  pollForFavicons();
  periodicallyAddFaviconsFromQueue();

};
