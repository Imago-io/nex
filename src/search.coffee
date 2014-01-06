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
      if result.kind is 'Collection'
        result.items = @sortassets(result.assets, assets)
        result.count = assets.length
      deferred.resolve(result)

    getAssetsFail = () ->
      # console.log 'getAssets fail'
      deferred.reject()


    getCollectionDone = (collection) =>
      return deferred.resolve(result) unless collection
      result = collection
      return deferred.resolve(result) unless fetchAssets

      #get assets
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


  getSearch: (params) ->
    @jqXHR = $.ajax(
      contentType: 'application/json'
      dataType: 'json'
      processData: false
      headers:
        'X-Requested-With': 'XMLHttpRequest'
        'NexClient'       : Nex.client
      type: 'POST'
      data: JSON.stringify(params)
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
      colparams = {'path' : params.path}
      @getSearch(colparams).done( (data, status, xhr) =>
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
      unless !!Object.keys(params).length
        toFetch = (id for id in collection.assets when not @globalExists(id))
        assets  = (@globalFind(id) for id in collection.assets when @globalExists(id))
      return deferred.resolve(assets) unless !!toFetch.length

      # fetch assets
      params.ids = toFetch
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
    querydict

  getSearchUrl: ->
    if Nex.client is 'public'
      if (Nex.data is 'online' and Nex.debug) then "http://#{Nex.tenant}.imagoapp.com/api/v2/search" else "/api/v2/search"
    else
      "/api/v2/search"

module.exports = Nex.Search