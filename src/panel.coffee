Nex  = @Nex or require('nex')

Nex.Panel =
  getData: (path) ->
    return @log "Panel: path is empty, aborting #{path}" unless path
    # return if path is @path

    @path = path
    # @log '(Nex.Panel) path: ', path if Nex.debug
    Nex.Models.Asset.get(path: path)
      .done(=>
        # @log '(Nex.Panel) result: ', arguments... if Nex.debug
        @trigger 'ready', arguments...
      )
      .fail(=> @log "Panel: Could not get data for panel #{path}")

  setTitle: (result) ->
    title = Nex.Models.Setting.findByAttribute('name', 'title')
    $('title').text("#{result.headline or 'Imago'} - #{title.value}")


module.exports = Nex.Panel