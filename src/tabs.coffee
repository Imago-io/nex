require("./panel")
Nex  = @Nex or require('nex')

class Tabs extends Spine.Controller
  @include Nex.Panel
  logPrefix:
    '(App) Tabs: '

  className: 'tabs'

  elements:
    '.tabNav' : 'tabNav'
    '.content': 'content'

  constructor: ->
    super

    @tmpl = require('views/tabs')

    @controllers = new Spine.Manager

    @bind 'ready', @render

    if @path then @getData @path else @active @getData

  render: (result) ->
    for col in result
      @html @tmpl(col: col)
      for asset in col.items
        @appendMedia (asset)


  appendMedia: (asset) =>
    # @log 'asset: ', asset
    return unless asset and el = @$(".#{asset.normname}")
    if asset.kind is 'Collection'
      kind = 'Slider'
    else
      kind= asset.kind
    media = new Nex.Widgets[kind]
      el:         el
      src:        asset.serving_url
      align:      asset.meta.crop?.value or 'center center'
      resolution: asset.resolution
      uuid:       asset.id
      formats:    asset.formats
      path:       asset.path
      lazy:       false
      animation:  asset.getMeta('animation', 'scalerotate')
      sizemode:   asset.getMeta('sizemode', ['crop'])[0]

      @add media

  add: (controller) ->
    @controllers.push controller

  clear: ->
    for controller in @controllers
      controller.release()

  deactivate: ->
    @clear()
    super
