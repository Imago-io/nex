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

    if @path then @getData @path else @active @getData

  onKeyup: (e) =>
    return unless @enablekeys and @isActive()
    switch e.keyCode
      when 37 then @prev()
      # when 38 then @log 'up'
      when 39 then @next()
      # when 40 then @log 'down'

  render: (result) =>
    @activate()
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
    assets = @asset.items or [@asset]

    @bind 'ready', @render

    if @asset.assets
      @getData @asset.path
    else
      @render()

  render: (result) ->
    assets = result?.items or [@asset]
    return unless assets?.length > 0

    if assets.length > 1 and @subslides
      for asset,i in assets
        @add new Slide
          asset: asset
          sizemode: @sizemode
          className: 'slidecontent'
    else
      for asset, i in assets
        @add @["asset#{i}"] = new Nex.Widgets[if asset in ['Image', 'Video'] then asset.kind else 'Image']
          src:          asset.serving_url
          align:        asset.meta.crop?.value or 'center center'
          resolution:   asset.resolution
          uuid:         asset.id
          formats:      asset.formats
          sizemode:     @sizemode
          lazy:         false
        html = asset.getMeta('html', '')
        @append html if html


  add: (controller) ->
    @controllers.push controller
    @append controller

  clear: ->
    for cont in @controllers
      @controllers[0].release()
    @controllers =[]
    @html ''
