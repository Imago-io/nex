Asset   = require('models/model').Asset
Setting = require('models/model').Setting


Panel =
  getData: (path) ->
    return @log "Panel: path is empty, aborting #{path}" unless path
    return if path is @path

    @path = path
    Asset.get(path: path)
      .done(=> @trigger 'ready', arguments...)
      .fail(=> @log "Panel: Could not get data for panel #{path}")

  setTitle: (result) ->
    title = Setting.findByAttribute('name', 'title')
    $('title').text("#{result.headline or 'Imago'} - #{title.value}")


module.exports = Panel