Nex  = @Nex or require('nex')

class Nex.Slider extends Spine.Controller
  @include Nex.Panel

  logPrefix:
    '(App) Nex.Slider: '

  className:
    'nexslider'

  events:
    'tap .next': 'next'
    'tap .prev': 'prev'

  defaults:
    animation:  'fade'
    easing:     'swing'
    sizemode:   'fit'
    current:    0
    height:     500

  constructor: ->
    # set default values before init
    for key, value of @defaults
      @[key] = value

    super

    @bind 'ready', @render
    if @path then @getData @path else @active @getData

    @el.height(@height)

    @html '<div class="prev"></div><div class="next"></div>'
    @manager = new Spine.Manager


  render: (result) =>
    for asset, i in result.items
      kind = if asset.kind is 'Collection' then 'Image' else asset.kind
      @add @["asset#{i}"] = new Nex.Widgets[kind]
        src:          asset.serving_url
        align:        asset.meta.crop?.value or 'center center'
        resolution:   asset.resolution
        uuid:         asset.id
        formats:      asset.formats
        sizemode:     'crop'
        lazy:         false
    @manager.controllers[@current].active()

  clear: ->
    for cont in @controllers
      @controllers[0].release()

  add: (controller) ->
    @manager.add(controller)
    @append(controller.el)

  next: =>
    return unless @current < (@manager.controllers.length - 1)
    @current++
    @manager.controllers[@current].active()

  prev: =>
    return unless @current > 0
    @current--
    @manager.controllers[@current].active()


module.exports = Nex.Slider


