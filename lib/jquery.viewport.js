// Generated by CoffeeScript 1.9.3
(function() {
  (function($) {
    $.belowthefold = function(element, settings) {
      var fold;
      fold = $(window).height() + $(window).scrollTop();
      return fold <= $(element).offset().top - settings.threshold;
    };
    $.abovethetop = function(element, settings) {
      var top;
      top = $(window).scrollTop();
      return top >= $(element).offset().top + $(element).height() - settings.threshold;
    };
    $.rightofscreen = function(element, settings) {
      var fold;
      fold = $(window).width() + $(window).scrollLeft();
      return fold <= $(element).offset().left - settings.threshold;
    };
    $.leftofscreen = function(element, settings) {
      var left;
      left = $(window).scrollLeft();
      return left >= $(element).offset().left + $(element).width() - settings.threshold;
    };
    $.inviewport = function(element, settings) {
      return !$.rightofscreen(element, settings) && !$.leftofscreen(element, settings) && !$.belowthefold(element, settings) && !$.abovethetop(element, settings);
    };
    return $.extend($.expr[":"], {
      "below-the-fold": function(a, i, m) {
        return $.belowthefold(a, {
          threshold: 0
        });
      },
      "above-the-top": function(a, i, m) {
        return $.abovethetop(a, {
          threshold: 0
        });
      },
      "left-of-screen": function(a, i, m) {
        return $.leftofscreen(a, {
          threshold: 0
        });
      },
      "right-of-screen": function(a, i, m) {
        return $.rightofscreen(a, {
          threshold: 0
        });
      },
      "in-viewport": function(a, i, m) {
        return $.inviewport(a, {
          threshold: 0
        });
      }
    });
  })(jQuery);

}).call(this);
