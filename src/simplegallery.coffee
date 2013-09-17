Nex  = @Nex or require('nex')

Nex.SimpleGallery =

  renderGallery: ->

  cur: 0

  next: =>
    return unless @cur < (@manager.controllers.length - 1)
    @cur++
    @manager.controllers[@cur].active()

  prev: =>
    return unless @cur > 0
    @cur--
    @manager.controllers[@cur].active()

  # add: (controller) ->
  #   @manager.add(controller)
  #   @append(controller)


module.exports = Nex.SimpleGallery