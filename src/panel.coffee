Nex  = @Nex or require('nex')
_ = require('underscore')

Nex.Panel =
  getData: (query) ->
    return @log "Panel: query is empty, aborting #{query}" unless query
    # return if path is @path
    @query = query
    if Nex.Utils.toType(query) is 'string'
      @query =
        [path: @query]

    @query = @toArray(@query)

    @promises = []
    @data = []

    # @log '(Nex.Panel) @query: ', @query if Nex.debug
    for q in @query
      @promises.push(Nex.Models.Asset.get(q, false if @query.length > 1)
        .done(=>
          # @log '(Nex.Panel) result: ', arguments...
          @data.push arguments...
        )
        .fail(=> @log "Panel: Could not get data for panel #{@query}")
      )

    $.when.apply($, @promises).done(=>
      @trigger 'ready', @data
    )

  getRelated: (query) ->
    """
      query =
        context : '/foo/bar'   # required -  path/uuid/asset
        field   : 'category'   # required -  field the related should be filtered of
        related : ['t1', 't2'] # optional -  values it should look for.
                               # if not passed to the query the asset field values are taken
        kind    : 'Image'      # optional - limit the request to specific kinds
        limit   : 5            # optional - default is 10

    """
    return @log "Panel: getRelated query is empty, aborting #{query}" unless query
    @relpromises = []
    @related     = []
    @relquery    = @toArray(query)
    for q in @relquery
      @relpromises.push(Nex.Models.Asset.get(q).done(=>
            @related.push arguments...
          )
          .fail(=> @log "Panel: Could not get related for panel #{@query}")
      )

    $.when.apply($, @relpromises).done(=>
      @trigger 'ready', @related
    )

  toArray: (elem) ->
    type = Nex.Utils.toType(elem)
    return @log 'Panel: no valid query' unless type in ['object', 'string', 'array']
    if Nex.Utils.toType(elem) is 'array' then elem else [elem]


  setTitle: (result) ->
    title = Nex.Models.Setting.findByAttribute('name', 'title')
    $('title').text("#{result.headline or 'Imago'} - #{title.value}")


module.exports = Nex.Panel