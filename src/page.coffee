Nex  = @Nex or require('nex')

Nex.Utils or= require('./utils')

class Nex.Page extends Spine.Controller
  @include Nex.Panel

  className:
    'page'

  logPrefix:
    "(App) Page: "

  constructor: ->
    super
    @el.addClass @class if @class
    @controllers = []

    @bind 'ready', @render
    @active @cleanUp


  tmpl404: ->
    "<h1 class='#{Nex.language}'>Page not Found</h1>"

  render: (result) ->
    @delay ->
      window.scrollTo(0,0)
    , 100
    return @html @tmpl404() unless result.length

  add: (controller) ->
    @controllers.push(controller)
    @append(controller)

  replaceWithWidget: (wrapper, controller) ->
    @controllers.push(controller)
    wrapper.replaceWith(controller.el or controller)

  appendWidget: (asset) ->
    return unless asset and el = @$(".#{asset.normname}")

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

  activate: ->
    $('body').on 'keyup.page', @onKeyup
    $('body').addClass @className
    super

  deactivate: ->
    $('body').off '.page'
    $('body').removeClass @className
    @clear()
    super

  clear: ->
    for cont in @controllers
      cont.release()
    @controllers = []

  cleanUp: (data, opts) ->
    @clear()
    @getData(data, opts)


  onKeyup: (e) =>
    return unless @isActive()
    key = Nex.Utils.getKeyName(e)
    @[key]() if typeof @[key] is 'function'

module.exports = Nex.Page
