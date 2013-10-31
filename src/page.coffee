Nex  = @Nex or require('nex')

Nex.Utils or= require('./uitls')

class Nex.Page extends Spine.Controller
  @include Nex.Panel

  className:
    'page'

  logPrefix:
    "(App) Page: "

  constructor: ->
    super
    @tmpl404 = '<h1>Page not Found</h1>'

    @controllers = []

    @bind 'ready', @render
    @active @getData

  render: (result) ->
    return @html @tmpl404(language: Nex.language) unless result.items?.length

  add: (controller) ->
    @controllers.push(controller)
    @append(controller)

  activate: ->
    $('body').on 'keyup.page', @onKeyup
    super

  deactivate: ->
    $('body').off '.page'
    @clear()
    super

  clear: ->
    for cont in @controllers
      cont.release()
    @controllers = []

  onKeyup: (e) =>
    return unless @isActive()
    key = Nex.Utils.getKeyName(e)
    @[key]() if typeof @[key] is 'function'

module.exports = Nex.Page
