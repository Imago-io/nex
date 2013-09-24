#
# * Viewport - jQuery selectors for finding elements in viewport
# *
# * Copyright (c) 2008-2009 Mika Tuupola
# *
# * Licensed under the MIT license:
# *   http://www.opensource.org/licenses/mit-license.php
# *
# * Project home:
# *  http://www.appelsiini.net/projects/viewport
# *
#
(($) ->
  $.belowthefold = (element, settings) ->
    fold = $(window).height() + $(window).scrollTop()
    fold <= $(element).offset().top - settings.threshold

  $.abovethetop = (element, settings) ->
    top = $(window).scrollTop()
    top >= $(element).offset().top + $(element).height() - settings.threshold

  $.rightofscreen = (element, settings) ->
    fold = $(window).width() + $(window).scrollLeft()
    fold <= $(element).offset().left - settings.threshold

  $.leftofscreen = (element, settings) ->
    left = $(window).scrollLeft()
    left >= $(element).offset().left + $(element).width() - settings.threshold

  $.inviewport = (element, settings) ->
    not $.rightofscreen(element, settings) and not $.leftofscreen(element, settings) and not $.belowthefold(element, settings) and not $.abovethetop(element, settings)

  $.extend $.expr[":"],
    "below-the-fold": (a, i, m) ->
      $.belowthefold a,
        threshold: 0

    "above-the-top": (a, i, m) ->
      $.abovethetop a,
        threshold: 0

    "left-of-screen": (a, i, m) ->
      $.leftofscreen a,
        threshold: 0

    "right-of-screen": (a, i, m) ->
      $.rightofscreen a,
        threshold: 0

    "in-viewport": (a, i, m) ->
      $.inviewport a,
        threshold: 0

) jQuery


