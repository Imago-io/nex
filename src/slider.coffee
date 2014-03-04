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
    easing:       'swing'
    sizemode:     'fit'
    current:      0
    autoplay:     true
    enablekeys:   true
    enablearrows: true
    sizemode:     'fit'
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
      when 37 then @prev()
      # when 38 then @log 'up'
      when 39 then @next()
      # when 40 then @log 'down'

  render: (result) =>
    # @log 'render result: ', result
    return unless result.length
    @activate() unless @isActive()
    # @log 'result: ', result
    for col in result
      # @log 'col in result: ', col
      for asset,i in col.items
        # @log 'asset in col.items', asset
        @add new Slide
          asset:     asset
          sizemode:  @sizemode
          subslides: @subslides
          height:    @height
          width:     @width
          noResize:  @noResize
          lazy:      @lazy
          align:     @align
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
    switch slide
      when 'first'        then next = 0
      when 'last'         then next = @getLast()
      when 'next'         then next = @getNext(@current)
      when 'prev'         then next = @getPrev(@current)
      else next = slide

    # loop
    if not @loop
      if @current is @slides.length - 1 and next is @getNext(@current)
        @trigger 'end'
        return
      if @current is 0 and next is @getPrev(@current)
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
    else if @current is @slides.length - 1
      @trigger 'last'
      @el.addClass 'last'
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

  render: (result) ->
    assets = result?.items or result

    if assets.length and @subslides
      for asset,i in assets
        @add new Slide
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
      @add @["asset"] = new Nex.Widgets[kind]
        src:          result.serving_url
        align:        result.meta.crop?.value or @align
        resolution:   result.resolution
        uuid:         result.id
        formats:      result.formats
        sizemode:     @sizemode
        height:       @height
        width:        @width
        noResize:     @noResize
        lazy:         @lazy
      html = result.getMeta('text', result.getMeta('html', ''))
      @append html if html

  activate: ->
    super
    for cont in @controllers
      cont?.preload()

  deactivate: ->
    super
    @el.removeClass('prev next')

  onDeck: ->
    for cont in @controllers
      cont?.preload()

  add: (controller) ->
    @controllers.push controller
    @append controller

  clear: ->
    for cont in @controllers
      @controllers[0].release()
    @controllers =[]
    @html ''
