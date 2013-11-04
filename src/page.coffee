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

    @controllers = []

    @bind 'ready', @render
    @active @getData

  tmpl404: ->
    "<h1 class='#{Nex.language}'>Page not Found</h1>"

  render: (result) ->
    return @html @tmpl404() unless result.items?.length

  add: (controller) ->
    @controllers.push(controller)
    @append(controller)

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

  onKeyup: (e) =>
    return unless @isActive()
    key = Nex.Utils.getKeyName(e)
    @[key]() if typeof @[key] is 'function'

module.exports = Nex.Page
