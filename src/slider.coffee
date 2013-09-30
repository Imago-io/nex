Nex  = @Nex or require('nex')

class Nex.Slider extends Spine.Controller
  @include Nex.Panel

  logPrefix:
    '(App) Nex.Slider: '

  className:
    'nexslider carousel'

  events:
    'tap .next': 'next'
    'tap .prev': 'prev'
    'keyup'    : 'onKeyup'

  defaults:
    animation:  'fade'
    easing:     'swing'
    sizemode:   'fit'
    current:    0
    height:     500
    autoplay:   true
    enablekeys: true

  constructor: ->
    # set default values before init
    for key, value of @defaults
      @[key] = value

    super
    @manager = new Spine.Manager

    @bind 'ready', @render

    document.addEventListener 'keydown', @onKeyup if @enablekeys

    if @path then @getData @path else @active @getData

    @el.height(@height)

    @html '<div class="prev"></div><div class="next"></div>'

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
      @add new Slide asset: asset
    @manager.controllers[@current].active()

  clear: ->
    for cont in @controllers
      @controllers[0].release()

  add: (controller) ->
    @manager.add(controller)
    @append(controller)

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

module.exports = Nex.Slider

class Slide extends Spine.Controller
  logPrefix:
    '(App) Slide: '

  className:
    'slide'

  constructor: ->
    super

    @controllers = []
    assets = @asset.items or [@asset]

    for asset,i in assets
      @add @["asset#{i}"] = new Nex.Widgets[if asset in ['Image', 'Video'] then asset.kind else 'Image']
        src:          asset.serving_url
        align:        asset.meta.crop?.value or 'center center'
        resolution:   asset.resolution
        uuid:         asset.id
        formats:      asset.formats
        sizemode:     'crop'
        lazy:         false

      html = asset.getMeta('html', '')
      @append html if html

  add: (controller) ->
    @controllers.push controller
    @append(controller)

  clear: ->
    for cont in @controllers
      @controllers[0].release()
    @controllers =[]
    @html ''

