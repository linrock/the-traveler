Components.InfiniteScrollFavicons = function() {

  var $d = $(document),
      $w = $(window);

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
    $html.appendTo($(".favicons .favicon-sheet"));
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
