require("./panel")
# require("./utils")

Nex  = @Nex or require('nex')

class Nex.Widgets.Slider extends Spine.Controller
  @include Nex.Panel

  logPrefix:
    '(App) Nex.Slider: '

  className:
    'nexslider'

  events:
    'tap .next' : 'goNext'
    'tap .prev' : 'goPrev'
    'swipeleft' : 'goNext'
    'swiperight': 'goPrev'
    'swipeLeft' : 'goNext'
    'swipeRight': 'goPrev'

  defaults:
    animation:    'fade'
    sizemode:     'fit'
    current:      0
    enablekeys:   true
    enablearrows: true
    enablehtml:   true
    subslides:    false
    loop:         true
    responsive:   true
    current:      0
    lazy:         false
    align:         'center center'
    controls:     false


  constructor: ->
    # set default values before init
    for key, value of @defaults
      @[key] = value

    super

    @el.addClass @animation
    @manager = new Spine.Manager

    @slides  = @manager.controllers
    @slidesObj = {}

    @bind 'ready', @render

    @id or= Nex.Utils.uuid()

    @touch = {}

    $(document).on "keydown.#{@id}", @onKeyup if @enablekeys

    @el.addClass @class if @class
    @el.data @data if @data

    @html '<div class="prev"></div><div class="next"></div>' if @enablearrows

    # fetch data or on active to fetch data
    if @path
      @getData @path
    else if @collection and @collection.length > 0
      @render @collection
    else
      @active @getData

    @el.addClass(@name) if @name

  onKeyup: (e) =>
    return unless @enablekeys and @isActive()
    switch e.keyCode
      when 37 then @goPrev()
      # when 38 then @log 'up'
      when 39 then @goNext()
      # when 40 then @log 'down'

  render: (result) =>
    # @log 'render result: ', result
    return unless result.length
    @activate() unless @isActive()
    # @log 'result: ', result
    for col in result
      # @log 'col in result: ', col, col.name
      return unless col.items.length > 0
      for asset,i in col.items
        # @log 'asset in col.items', asset, asset.name
        @add @slidesObj[asset.normname] = new Slide
          slider:      @
          asset:       asset
          sizemode:    @sizemode
          subslides:   @subslides
          height:      @height
          width:       @width
          responsive:  @responsive
          lazy:        @lazy
          align:       @align
          enablehtml:  @enablehtml
          controls:    @controls

    @goto @current

    @delay =>
      @trigger 'rendered', result

  clear: ->
    for cont in @controllers
      @controllers[0].release()

  add: (controller) ->
    @manager.add controller
    @append controller

  goNext: (e) =>
    @direction = 'next'
    @goto 'next'

  goPrev: (e) =>
    @direction = 'prev'
    @goto 'prev'

  goto: (slide) ->
    # @log 'goto', slide
    return @log 'no slides' unless @slides

    @trigger 'slide', @

    switch slide
      when 'first'        then next = 0
      when 'last'         then next = @getLast()
      when 'next'         then next = @getNext(@current)
      when 'prev'         then next = @getPrev(@current)
      else next = Number(slide)

    # @log 'goto next', next

    # don't navigate if slider not ready yet
    # @log @slides.length
    return unless @slides.length

    #If slider has one slide
    if @slides.length is 1
      @enablearrows = false
      @enablekeys   = false
      @slides[@current].active?()
      @el.addClass('first last')
      if slide is 'next' then @trigger 'end' else if slide is 'prev' then @trigger 'start'
      return

    # loop
    unless @loop
      if @slides.length > 1
        if @current is @slides.length - 1 and next is 0 and @direction is 'next'
          @trigger 'end'
          return
        else if @current is 0 and next is @slides.length - 1 and @direction is 'prev'
          @trigger 'start'
          return

    # clean up
    @slides[@prev]?.el.removeClass 'prevslide'
    @slides[@next]?.el.removeClass 'nextslide'

    # new slides
    @current = next
    @prev    = @getPrev(@current)
    @next    = @getNext(@current)

    @slides[@prev].el.addClass 'prevslide'
    @slides[@next].el.addClass 'nextslide'

    # @log 'goto @current', @current

    @slides[@current]?.active()

    @trigger 'change', @
    @direction = ''

    # trigger class and fire events
    if @current is 0
      @trigger 'first'
      @el.addClass 'first'
      @el.removeClass 'last'
    else if @current is @slides.length - 1
      @trigger 'last'
      @el.addClass 'last'
      @el.removeClass 'first'
    else
      @el.removeClass('first last')

  getPrev: (i) ->
    if i is 0 then @slides.length - 1 else i - 1

  getNext: (i) ->
    if i is @slides.length - 1 then  0 else i + 1

  getLast: () ->
    @slides.length - 1

  release: ->
    $(document).off "keydown.#{@id}" if @enablekeys
    for cont in @slides
      @slides[0].release()
    super

  preload: ->
    for cont in @slides
      continue unless cont.isActive()
      cont.preload?()

module.exports = Nex.Widgets.Slider


class Slide extends Spine.Controller
  @include Nex.Panel

  logPrefix:
    '(App) Slide: '

  className:
    'slide'

  events:
    'tap': 'onClick'

  constructor: ->
    super

    @controllers = []
    # assets = @asset.items or [@asset]

    # we have a collection fetch data for col path if subslides enabled
    if @asset.assets and @subslides
      @bind 'ready', @render
      @getData @asset.path
    else
      @render([@asset])

  onClick: ->
    @slider.trigger 'click', @

  render: (result) ->
    # git  'render result', result
    for col in result
      # @log col
      if col.kind is 'Collection' and @subslides
        # @log 'subslides slide', @sizemode, @align
        for asset,i in col.items
          @add new Slide
            slider:     @slider
            asset:      asset
            sizemode:   @sizemode
            className:  "slidecontent #{asset.getMeta('crop', '')} #{asset.getMeta('cssclass', '')}"
            # height:     @height
            # width:      @width
            responsive: @responsive
            lazy:       @lazy
            align:      @align
            enablehtml: @enablehtml
            controls:   @controls

      else
        @kind = if col.kind in ['Image', 'Video'] then col.kind else 'Image'
        # @log 'crop', col.getMeta('crop', 'center center')
        return @log 'no serving_url for widget in slide' unless col.serving_url
        @add @["media"] = new Nex.Widgets[@kind]
          src:          col.serving_url
          align:        col.getMeta('crop', 'center center')
          resolution:   col.resolution
          uuid:         col.id
          formats:      col.formats
          sizemode:     col.getMeta('sizemode', [@sizemode])[0]
          height:       @height
          width:        @width
          responsive:   @responsive
          lazy:         @lazy
          controls:     @controls

        # render html
        if typeof @enablehtml is 'boolean' and @enablehtml
          # @log 'boolean and true'
          html = col.getMeta('text', col.getMeta('html', ''))

        else if typeof @enablehtml is 'string'
          # @log 'string'
          html = col.getMeta('text', col.getMeta(@enablehtml, ''))

        else if typeof @enablehtml is 'function'
          # @log 'function'
          html = @enablehtml(col)

        @append html if html

      if @kind is 'Video'
        @listenTo @slider, 'change', () =>
            @media.preload()
            @media.pause()

  activate: ->
    super
    cont.preload?() for cont in @controllers if @subslides

  deactivate: ->
    super
    @el.removeClass('prev next')

  preload: ->
    for cont in @controllers
      cont.preload?()

  add: (controller) ->
    @controllers.push controller
    @append controller

  clear: ->
    for cont in @controllers
      @controllers[0].release()
    @controllers =[]
    @html ''

  release: ->
    @clear()
    super
