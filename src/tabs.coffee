require("./panel")
Nex  = @Nex or require('nex')

class Nex.Widgets.Tabs extends Spine.Controller
  @include Nex.Panel
  logPrefix: '(App) Tabs: '

  className: 'tabs'

  elements:
    'nav'     : 'navigation'

  events:
    'tap nav a' : 'onClick'

  constructor: ->
    super

    @html """
            <nav></nav>
          """

    @controllers = []

    @bind 'ready', @render

    if @path then @getData @path else @active @getData

  render: (result) ->
    for col in result
      # create tabs
      for asset, i in col.items
        @navigation.append "<a href='#tab#{i}'>#{asset.getMeta('title', asset.getMeta('headline'))}</a>"
        # @section.append    "<article id='tab#{i}'>#{asset.getMeta('text', asset.getMeta('html'))}</article>"
        @add new Tab
          i    : i
          asset: asset


    @links = @$('nav a')
    @links.eq(0).addClass('active')

    @content = @$('article')
    @content.eq(0).addClass('active')

  add: (controller) ->
    @controllers.push(controller)
    @append(controller)

  onClick: (e)->
    e.preventDefault()

    @links.removeClass   'active'
    @content.removeClass 'active'

    target = $(e.target)
    target.addClass 'active'
    @content.filter(target.attr('href')).addClass('active')

  clear: ->
    for controller in @controllers
      controller.release()

  deactivate: ->
    @clear()
    super

module.exports = Nex.Widgets.Tabs



class Tab extends Spine.Controller
  @include Nex.Panel
  logPrefix: '(App) Tab: '

  tag: 'article'

  constructor: ->
    super
    @el.attr 'id', "tab#{@i}"
    @controllers = []

    if @asset.kind is 'Collection'
      @bind 'ready', @render
      @getData @asset.path
    else
      @render([@asset])


  render: (result) ->
    for asset in result
      @html asset.getMeta('text', asset.getMeta('html'))

      # add widgets
      @appendWidget asset
      if asset.kind is 'Collection'
        for item in asset.items
          @appendWidget item

      break

  appendWidget: (asset) ->
    return unless asset and el = @$(".#{asset.normname}")[0]
    @controllers.push new Nex.Widgets[if asset.kind is 'Collection' then 'Slider' else asset.kind]
      el:         el
      src:        asset.serving_url
      align:      asset.getMeta 'crop', 'center center'
      resolution: asset.resolution
      uuid:       asset.id
      formats:    asset.formats
      path:       asset.path
      lazy:       false
      animation:  asset.getMeta 'animation', 'scalerotate'
      sizemode:   asset.getMeta('sizemode', ['crop'])[0]

  deactivate: ->
    @clear()
    super

  clear: ->
    for cont in @controllers
      cont.release()
    @controllers = []
