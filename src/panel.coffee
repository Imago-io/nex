Nex  = @Nex or require('nex')

Nex.Panel =
  getData: (path) ->
    return @log "Panel: path is empty, aborting #{path}" unless path
    return if path is @path

    @path = path
    Nex.Models.Asset.get(path: path)
      .done(=> @trigger 'ready', arguments...)
      .fail(=> @log "Panel: Could not get data for panel #{path}")

  setTitle: (result) ->
    title = Nex.Models.Setting.findByAttribute('name', 'title')
    $('title').text("#{result.headline or 'Imago'} - #{title.value}")


module.exports = Nex.Panel