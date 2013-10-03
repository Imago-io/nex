Nex  = @Nex or require('nex')

class Nex.Widgets.Html extends Spine.Controller
  @include Nex.Panel

  logPrefix:
    '(App) Nex.Html: '

  constructor: ->
    super

    headline = @asset.getMeta('headline')
    @append "<h1>#{headline}<H1>" if headline

    html = @asset.getMeta('html')
    @append html if html


module.exports = Nex.Widgets.Html
