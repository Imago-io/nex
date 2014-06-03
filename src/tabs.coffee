require("./panel")
Nex  = @Nex or require('nex')

class Nex.Widgets.Tabs extends Spine.Controller
  @include Nex.Panel
  logPrefix:
    '(App) Tabs: '

  className: 'tabs'

  elements:
    '.tabNav' : 'tabNav'
    '.tabLink': 'tabLink'
    '.content': 'content'
    '.tab'    : 'tab'

  events:
    'tap .tabLink' : 'onClick'

  constructor: ->
    super

    @html(
      """
        <div class="tabNav"></div>
        <div class="content"></div>
      """
    )

    @controllers = []

    @bind 'ready', @render

    if @path then @getData @path else @active @getData

  render: (result) ->
    for col in result
      @tabNav.append "<a href='#tab#{i}' class='tabLink'>#{asset.getMeta('title')}</a>" for asset, i in col.items
      @content.append "<div id='#tab#{i}' class='tab'>#{asset.getMeta('text')}</div>" for asset, i in col.items
      for asset in col.items
        @appendMedia (asset)

    @tabLink.eq(0).addClass('active')
    @tab.eq(0).addClass('active')

  onClick: (e)->
    e.preventDefault()

    @tabLink.removeClass 'active'
    @tab.removeClass 'active'

    $(e.target).addClass 'active'
    @tab.filter(target.attr('href')).addClass('active')

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
