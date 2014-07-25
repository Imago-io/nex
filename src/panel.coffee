Nex  = @Nex or require('nex')
_ = require('underscore')

Nex.Panel =
  getData: (query, options={}) ->
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
    abortable   = false if @query.length > 1 or not options.abortable
    fetchassets = if options.fetchAsses is undefined then true else options.fetchAsses
    ajax        = if options.ajax is undefined then true else options.ajax
    for q in @query
      @promises.push(Nex.Models.Asset.get(q, abortable, fetchassets, ajax)
        .done((result) =>
          # @log '(Nex.Panel) result: ', result
          return if not result.id and result.count is 0
          @data.push result
        )
        .fail(=> @log "Panel: Could not get data for panel #{@query}")
      )

    $.when.apply($, @promises).done(=>
      @trigger 'ready', @data
    )

  getRelated: (query, options={}) ->
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
    # @log '@relquery', @relquery
    for q in @relquery
      @relpromises.push(Nex.Models.Asset.get(q, false if @relquery.length > 1 or not options.abortable).done(=>
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
