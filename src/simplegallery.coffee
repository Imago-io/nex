Nex  = @Nex or require('nex')

Nex.SimpleGallery =

  cur: 0

  next: ->
    return unless @cur < (@manager.controllers.length - 1)
    @cur++
    @manager.controllers[@cur].active()

  prev: ->
    return unless @cur > 0
    @cur--
    @manager.controllers[@cur].active()


module.exports = Nex.SimpleGallery