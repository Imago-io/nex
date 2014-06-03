require("./panel")
Nex  = @Nex or require('nex')

class Nex.Widgets.Tabs extends Spine.Controller
  @include Nex.Panel
  logPrefix:
    '(App) Tabs: '

  className: 'tabs'

  elements:
    'nav' : 'navigation'
    'nav a': 'links'
    'section': 'section'
    'section article': 'content'

  events:
    'tap nav a' : 'onClick'

  constructor: ->
    super

    @html(
      """
        <nav></nav>
        <section></section>
      """
    )

    @controllers = []

    @bind 'ready', @render

    if @path then @getData @path else @active @getData

  render: (result) ->
    for col in result
      @navigation.append "<a href='#tab#{i}'>#{asset.getMeta('title', asset.getMeta('headline'))}</a>" for asset, i in col.items
      @section.append "<article id='#tab#{i}'>#{asset.getMeta('text', asset.getMeta('html'))}</article>" for asset, i in col.items
      for asset in col.items
        @appendMedia (asset)

    @links.eq(0).addClass('active')
    @content.eq(0).addClass('active')

  onClick: (e)->
    e.preventDefault()

    @links.removeClass 'active'
    @content.removeClass 'active'

    $(e.target).addClass 'active'
    @content.filter(target.attr('href')).addClass('active')

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

module.exports = Nex.Widgets.Tabs
