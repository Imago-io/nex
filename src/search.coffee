Nex  = @Nex or require('nex')

Nex.Search =

  get: (params, abortable, fetchAssets=true) ->
    if abortable is undefined and Nex.client is 'public'
      abortable = true

    @jqXHR.abort('abort') if abortable and @jqXHR

    params   = @objListToDict(params)
    deferred = $.Deferred()
    promise  = deferred.promise()

    result =
      items: []
      count: 0

    getAssetsDone = (assets) =>
      # console.log 'getAssetsDone', assets
      if result.kind is 'Collection'
        # console.log 'getAssetsDone', result
        result.items = @sortassets(result.assets, assets)
        result.count = assets.length
        # console.log 'offset', @offset, 'assets', result.assets.length, 'page', @page, 'pagesize', @pagesize
        if @page
          result.next  = if result.items.length is @pagesize then @page + 1
          result.prev  = if @page > 1 then @page - 1
        # console.log 'result', result
      deferred.resolve(result)

    getAssetsFail = () ->
      # console.log 'getAssets fail'
      deferred.reject()

    getCollectionDone = (collection) =>
      # console.log 'getCollectionDone', collection
      return deferred.resolve(result) unless collection
      result = collection
      return deferred.resolve(result) unless fetchAssets

      # get assets
      @getAssets(collection, params)
        .done(getAssetsDone)
        .fail(getAssetsFail)

    getCollectionFail = () ->
      # console.log 'getCollection fail'
      deferred.reject()

    getSearchDone = (data, status, xhr) =>
      assets = @parseData(data)
      result.items = assets
      result.count = assets.length
      deferred.resolve(result)

    getSearchFail = (xhr, statusText, error) ->
      # console.log 'get search fail', arguments
      deferred.reject(arguments)

    if params.path
      @getCollection(params)
        .done(getCollectionDone)
        .fail(getCollectionFail)
    else
      @getSearch(params)
        .done(getSearchDone)
        .fail(getSearchFail)

    promise


  containedInExcludes: (params) ->
    # function that determines which collections have to be
    # excluded from the search to avoid overwriting data
    return params if not params.hasOwnProperty('contained_in')
    objid    = params.contained_in[0]
    colModel = @get_model('Collection')
    excludes = colModel.select((item) -> objid in item.assets)
    params.excludes = (obj.id for obj in excludes)
    params

  getSearch: (params) ->

    @jqXHR = $.ajax(
      contentType: 'application/json'
      dataType: 'json'
      processData: false
      headers:
        'X-Requested-With': 'XMLHttpRequest'
        'NexClient'       : Nex.client
      type: 'POST'
      data: JSON.stringify(@containedInExcludes(params))
      url:  @getSearchUrl()
    ).always( => @jqXHR = null)

    @jqXHR

  getCollection: (params) ->
    deferred = $.Deferred()
    promise  = deferred.promise()

    path = params.path[0]
    path = path.replace(/\/$/, "") unless path is '/'

    Collection = @get_model('Collection')
    collection = Collection.findByAttribute('path', path)

    if collection
      return deferred.resolve(collection)
    else
      # fetch collection
      @getSearch({'path' : params.path}).done( (data, status, xhr) =>
        delete params.path
        collection = @parseData(data)[0]
        deferred.resolve(collection)
      )

    promise

  getAssets: (collection, params) ->
    deferred = $.Deferred()
    promise  = deferred.promise()

    delete params.path


    if collection.kind is 'Collection'
      toFetch = collection.assets
      assets  = []

      @page     = if parseInt(params.page) then params.page else null
      @pagesize = collection.meta.pagesize?.value or 5000

      # get contained assets
      ids = collection.assets unless !!Object.keys(params).length

      # get contained filtered by kind
      if Object.keys(params).length is 1 and params.hasOwnProperty('kind')
        ids = (id for id in collection.assets when @id_to_kind(id) in params.kind)

      # get contained assets paged and aventually filtered
      if Object.keys(params).length is 1 and params.hasOwnProperty('page')
        @offset = (@page - 1) * params.pagesize = @pagesize
        ids     = collection.assets[@offset...@pagesize * @page]


      if ids?.length
        params.ids = toFetch = (id for id in ids when not @globalExists(id))
        assets  = (@globalFind(id) for id in ids when @globalExists(id))

      return deferred.resolve(assets) unless !!toFetch.length

      # fetch assets
      params.ancestor = collection.id

      @getSearch(params).done( (data, status, xhr) =>
        assets = assets.concat(@parseData(data))
        deferred.resolve(assets)
      )
    else
      deferred.resolve([])

    promise

  sortassets: (ids, assets) ->
    orderedlist = []
    for id in ids
      for asset, i in assets
        if asset.id is id
          orderedlist.push(asset)
          # assets.splice(i, 1)
          break
    orderedlist

  parseData: (data) ->
    objs = []
    if typeof data is 'string'
      data = JSON.parse(data)
    for obj in data
      asset = @create_or_update(obj, {ajax:false, skipAc: true})
      objs.push asset
    objs

  objListToDict: (obj_or_list) ->
    querydict = {}
    if Spine.isArray(obj_or_list)
      for elem in obj_or_list
        for key of elem
          value = elem[key]
          querydict[key] or= []
          querydict[key].push(value)
    else
      for key of obj_or_list
        value = obj_or_list[key]
        querydict[key] = if Spine.isArray(value) then value else [value]

    if querydict.collection?
      querydict['path'] = querydict.collection
      delete querydict.collection
    for key in ['page', 'pagesize']
      if querydict.hasOwnProperty(key)
        querydict[key] = querydict[key][0]
    querydict

  getSearchUrl: ->
    if (Nex.data is 'online' and Nex.debug) then "http://#{Nex.tenant}.imagoapp.com/api/v2/search" else "/api/v2/search"


module.exports = Nex.Search