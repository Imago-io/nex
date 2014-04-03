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
    'swipeLeft' : 'goNext'
    'swipeRight': 'goPrev'
    'keyup'     : 'onKeyup'

  defaults:
    animation:    'fade'
    sizemode:     'fit'
    current:      0
    enablekeys:   true
    enablearrows: true
    enablehtml:   true
    subslides:    false
    loop:         true
    noResize:     false
    current:      0
    lazy:         false
    align:         'center center'


  constructor: ->
    # set default values before init
    for key, value of @defaults
      @[key] = value

    super

    @el.addClass @animation
    @manager = new Spine.Manager
    @slides  = @manager.controllers

    @bind 'ready', @render

    @id = Nex.Utils.uuid()

    $(document).on "keydown.#{@id}", @onKeyup if @enablekeys

    @el.addClass @class if @class

    @html '<div class="prev"></div><div class="next"></div>' if @enablearrows

    # fetch data or on active to fetch data
    if @path then @getData @path else @active @getData

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
        @add new Slide
          slider:      @
          asset:       asset
          sizemode:    @sizemode
          subslides:   @subslides
          height:      @height
          width:       @width
          noResize:    @noResize
          lazy:        @lazy
          align:       @align
          enablehtml:  @enablehtml
    @goto @current

  clear: ->
    for cont in @controllers
      @controllers[0].release()

  add: (controller) ->
    @manager.add controller
    @append controller

  goNext: =>
    @goto 'next'

  goPrev: =>
    @goto 'prev'

  goto: (slide) ->
    return @log 'no slides' unless @slides

    switch slide
      when 'first'        then next = 0
      when 'last'         then next = @getLast()
      when 'next'         then next = @getNext(@current)
      when 'prev'         then next = @getPrev(@current)
      else next = Number(slide)

    # don't navigate if slider not ready yet
    return unless @slides.length

    #If slider has one slide
    if @slides.length is 1
      @enablearrows = false
      @enablekeys   = false
      @slides[@current].active?()
      @el.addClass('first last')
      return

    # loop
    if not @loop
      if @current is @slides.length - 1 and next is @getNext(@current)
        unless @slides.length is 2
          @trigger 'end'
          return
      if @current is 0 and next is @getPrev(@current)
        unless @slides.length is 2
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

    @slides[@current]?.active()

    #make sure next slides are loaded
    @slides[@prev].onDeck()
    @slides[@next].onDeck()

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
      @render(@asset)

  onClick: ->
    @slider.trigger 'click', @

  render: (result) ->
    result = result[0] if result.length is 1
    assets = result?.items or result
    # @log 'assets: ', assets

    if assets.length and @subslides
      for asset,i in assets
        @add new Slide
          slider:    @slider
          asset:     asset
          sizemode:  @sizemode
          className: 'slidecontent'
          height:    @height
          width:     @width
          noResize:  @noResize
          lazy:      @lazy
          align:     @align
    else
      kind = if result.kind in ['Image', 'Video'] then result.kind else 'Image'
      @add @["media"] = new Nex.Widgets[kind]
        src:          result.serving_url
        align:        result.meta.crop?.value or @align
        resolution:   result.resolution
        uuid:         result.id
        formats:      result.formats
        sizemode:     result.getMeta('sizemode', [@sizemode])[0]
        height:       @height
        width:        @width
        noResize:     @noResize
        lazy:         @lazy

      # render html
      if typeof @enablehtml is 'boolean' and @enablehtml
        # @log 'boolean and true'
        html = result.getMeta('text', result.getMeta('html', ''))

      else if typeof @enablehtml is 'string'
        # @log 'string'
        html = result.getMeta('text', result.getMeta(@enablehtml, ''))

      else if typeof @enablehtml is 'function'
        # @log 'function'
        html = @enablehtml(result)

      @append html if html

  activate: ->
    super
    cont.preload?() for cont in @controllers if @subslides


  deactivate: ->
    super
    @el.removeClass('prev next')

  onDeck: ->
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
