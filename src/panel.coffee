Nex  = @Nex or require('nex')

Nex.Panel =
  getData: (query) ->
    return @log "Panel: query is empty, aborting #{query}" unless query
    # return if path is @path

    if typeof query is 'string'
      query =
        path: query

    @query = query

    @log '(Nex.Panel) @query: ', @query if Nex.debug
    Nex.Models.Asset.get(query, false)
      .done(=>
        @log '(Nex.Panel) result: ', arguments..., @ if Nex.debug
        @trigger 'ready', arguments...
      )
      .fail(=> @log "Panel: Could not get data for panel #{@query}")

  setTitle: (result) ->
    title = Nex.Models.Setting.findByAttribute('name', 'title')
    $('title').text("#{result.headline or 'Imago'} - #{title.value}")


module.exports = Nex.Panel