/* eslint-disable */
(function() {
  this.Activities = (function() {
    function Activities() {
      this.emptyState = document.querySelector('#js-activities-empty-state');
      Pager.init(20, true, false, this.pagerCallback.bind(this));
      $(".event-filter-link").on("click", (function(_this) {
        return function(event) {
          event.preventDefault();
          _this.toggleFilter($(event.currentTarget));
          return _this.reloadActivities();
        };
      })(this));
    }

    Activities.prototype.pagerCallback = function(data) {
      if (data.count === 0 && this.emptyState) this.emptyState.classList.remove('hidden');
      this.updateTooltips();
    };

    Activities.prototype.updateTooltips = function() {
      gl.utils.localTimeAgo($('.js-timeago', '.content_list'));
    };

    Activities.prototype.reloadActivities = function() {
      $(".content_list").html('');
      return Pager.init(20, true, false, this.pagerCallback.bind(this));
    };

    Activities.prototype.toggleFilter = function(sender) {
      var filter = sender.attr("id").split("_")[0];
      if (this.emptyState) this.emptyState.classList.add('hidden');

      $('.event-filter .active').removeClass("active");
      Cookies.set("event_filter", filter);

      sender.closest('li').toggleClass("active");
    };

    return Activities;

  })();

}).call(this);
