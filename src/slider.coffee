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

  onKeyup: (e) =>
    return unless @enablekeys and @isActive()
    switch e.keyCode
      when 37 then @prev()
      # when 38 then @log 'up'
      when 39 then @next()
      # when 40 then @log 'down'

  render: (result) =>
    @activate() unless @isActive()
    for asset,i in result.items
      @add new Slide
        asset:     asset
        sizemode:  @sizemode
        subslides: @subslides
    @manager.controllers[@current].active()

  clear: ->
    for cont in @controllers
      @controllers[0].release()

  add: (controller) ->
    @manager.add controller
    @append controller

  next: =>
    if @current < (@manager.controllers.length - 1)
      @current++
    else
      @current = 0
    @manager.controllers[@current].active()

  prev: =>
    if @current > 0
      @current--
    else
      @current = @manager.controllers.length - 1
    @manager.controllers[@current].active()

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

    # @log 'slide render', result, assets, assets.length

    if assets.length and @subslides
      for asset,i in assets
        @add new Slide
          asset: asset
          sizemode: @sizemode
          className: 'slidecontent'
    else
      kind = if result.kind in ['Image', 'Video'] then result.kind else 'Image'
      @add @["asset"] = new Nex.Widgets[kind]
        src:          result.serving_url
        align:        result.meta.crop?.value or 'center center'
        resolution:   result.resolution
        uuid:         result.id
        formats:      result.formats
        sizemode:     @sizemode
        lazy:         false
      html = result.getMeta('html', '')
      @append html if html

  add: (controller) ->
    @controllers.push controller
    @append controller

  clear: ->
    for cont in @controllers
      @controllers[0].release()
    @controllers =[]
    @html ''
