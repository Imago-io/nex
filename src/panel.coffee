Nex  = @Nex or require('nex')
_ = require('underscore')

Nex.Panel =
  getData: (query) ->
    return @log "Panel: query is empty, aborting #{query}" unless query
    # return if path is @path
    if Nex.Utils.toType(query) is 'string'
      @query =
        [path: query]

    else if Nex.Utils.toType(query) is 'array'
      @query = query

    else if Nex.Utils.toType(query) is 'object'
      @log 'I am an Object'
      @query = [query]

    else
      return @log 'Panel: no valid query'

    # @log '@query: ', @query

    @promises = []
    @data = []

    # @log '(Nex.Panel) @query: ', @query if Nex.debug
    for q in @query
      @promises.push(Nex.Models.Asset.get(q, false)
        .done(=>
          # @log '(Nex.Panel) result: ', arguments...
          @data.push arguments...
        )
        .fail(=> @log "Panel: Could not get data for panel #{@query}")
      )

    $.when.apply($, @promises).done(=>
      # @log 'done @promises, @data: ', @promises, @data
      @trigger 'ready', @data
    )

  setTitle: (result) ->
    title = Nex.Models.Setting.findByAttribute('name', 'title')
    $('title').text("#{result.headline or 'Imago'} - #{title.value}")


module.exports = Nex.Panel