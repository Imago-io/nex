require("./panel")

Nex  = @Nex or require('nex')

class Nex.Widgets.Slider extends Spine.Controller
  @include Nex.Panel

  logPrefix:
    '(App) Nex.Slider: '

  className:
    'nexslider'

  events:
    'tap .next': 'next'
    'tap .prev': 'prev'
    'swipeLeft': 'next'
    'swipeRight': 'prev'
    'keyup'    : 'onKeyup'

  defaults:
    animation:  'fade'
    easing:     'swing'
    sizemode:   'fit'
    current:    0
    autoplay:   true
    enablekeys: true
    sizemode:   'fit'
    subslides:  false
    loop:       true
    noResize:   false
    current:    0
    lazy:       false


  constructor: ->
    # set default values before init
    for key, value of @defaults
      @[key] = value

    super
    @el.addClass @animation
    @manager = new Spine.Manager

    @bind 'ready', @render

    document.addEventListener 'keydown', @onKeyup if @enablekeys

    @el.addClass @class if @class

    @html '<div class="prev"></div><div class="next"></div>'

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
    return unless result?.assets.length
    @activate() unless @isActive()
    for asset,i in result.items
      @add new Slide
        asset:     asset
        sizemode:  @sizemode
        subslides: @subslides
        height:    @height
        width:     @width
        noResize:  @noResize
        lazy:      @lazy
    @goto @current

  clear: ->
    for cont in @controllers
      @controllers[0].release()

  add: (controller) ->
    @manager.add controller
    @append controller

  next: =>
    @goto(@current + 1)

  prev: =>
    @goto(@current - 1)

  goto: (slide) ->
    switch slide
      when 'first' then next = 0
      when 'last'  then next = @manager.controllers.length - 1
      else next = slide

    @current = next
    @manager.controllers[@current]?.active()
    @el.removeClass 'first last'

    if @current is 0
      @trigger 'first'
      @el.addClass 'first'

    if @current is @manager.controllers.length - 1
      @trigger 'last'
      @el.addClass 'last'




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
    else
      kind = if result.kind in ['Image', 'Video'] then result.kind else 'Image'
      @add @["asset"] = new Nex.Widgets[kind]
        src:          result.serving_url
        align:        result.meta.crop?.value or 'center center'
        resolution:   result.resolution
        uuid:         result.id
        formats:      result.formats
        sizemode:     @sizemode
        height:       @height
        width:        @width
        noResize:     @noResize
        lazy:         @lazy
      html = result.getMeta('html', '')
      @append html if html

  # activate: ->
  #   super
  #   for cont in @controllers
  #     cont.preload()

  add: (controller) ->
    @controllers.push controller
    @append controller

  clear: ->
    for cont in @controllers
      @controllers[0].release()
    @controllers =[]
    @html ''
