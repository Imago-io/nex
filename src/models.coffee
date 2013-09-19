# normalize    = require('lib/utils').normalize


Search =

  get: (params) ->
    params   = @_objListToDict(params)
    deferred = $.Deferred()
    promise  = deferred.promise()

    result =
      items: []
      count: 0

    # @jqXHR.abort('abort') if @jqXHR

    getAssetsDone = (assets) =>
      if assets.length and result.kind is 'Collection'
        result.items = @sortassets(result.assets, assets)
        result.count = assets.length

      deferred.resolve(result)

    getAssetsFail = () ->
      # console.log 'getAssets fail'
      deferred.reject()


    getCollectionDone = (collection) =>
      return deferred.resolve(result) unless collection
      result = collection

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
        'NexClient':        'public'
      type: 'POST'
      data: JSON.stringify(params)
      url:  if Spine.debug then "http://#{Spine.settings.tenant}.imagoapp.com/api/v2/search" else "/api/v2/search"
    )

    @jqXHR

  getCollection: (params) ->
    deferred = $.Deferred()
    promise  = deferred.promise()

    path = params.path[0]
    Collection = @get_model('Collection')
    collection = Collection.findByAttribute('path', path)

    if collection
      return deferred.resolve(collection)
    else
      # fetch collection
      @getSearch(params).done( (data, status, xhr) =>
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
      asset = @create_or_update(obj, {ajax:false})
      objs.push asset
    objs

  objListToDict: (list) ->
    obj = {}
    _.map list, (item) ->
      for key,value of item
        if obj[key]
          obj[key].push value
        else
          obj[key] = [value]

    # convert key: collection to path
    if obj.collection?
      obj['path'] = obj.collection
      delete obj.collection

    # console.log obj
    obj

  _objListToDict: (obj_or_list) ->
    querydict = {}
    if Spine.isArray(obj_or_list)
      for elem in obj_or_list
        for key of elem
          value = elem[key]
          if querydict[key]
            querydict[key].push(value)
          else
            querydict[key] = [value]
    else
      for key of obj_or_list
        value = obj_or_list[key]
        if not Spine.isArray(value)
          querydict[key] = [value]
        else
          querydict[key] = value

    if querydict.collection?
      querydict['path'] = querydict.collection
      delete querydict.collection
    querydict


class Asset extends Spine.Model
  @configure 'Asset'

  @extend Search

  @id_to_kind: (id) ->
    if id.indexOf('Collection-') == 0
      kind = 'Collection'
    else if id.indexOf('Generic-') == 0
      kind = 'Generic'
    else if id.indexOf('Proxy-') == 0
      kind = 'Proxy'
    else if id.indexOf('Order-') == 0
      kind = 'Order'
    else if id.match /[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}/
      kind = 'Image'
    else if id.match /[0-9a-z]{56}/
      kind = 'Video'
    return kind

  @globalFind: (id) ->
    return @get_model(id).find(id)

  @globalExists: (id) ->
    return @get_model(id).exists(id)

  @get_model: (id_or_kind) ->
    return Nex.Models[id_or_kind] or Nex.Models[@id_to_kind(id_or_kind)]

  @create_or_update: (attrs, options) ->
    model = @get_model(attrs.id)
    return model.create(attrs, options) unless model.exists(attrs.id)
    model.update(attrs.id, attrs, options)

  getMeta: (field, fallback='') ->
    return fallback unless field
    @meta[field]?.value or fallback

  # canonicalPath: ->
  #   try
  #     asset = Asset.get_model('Collection').find(@canonical)
  #     asset.path()
  #   catch e
  #     return

class Collection extends Asset
  @configure 'Collection', 'kind', 'name', 'meta', 'path', 'serving_url',
                           'date_created', 'date_modified', 'resolution', 'sort_by',
                           'sort_order', 'assets', 'hidden', 'normname', 'canonical'

  # assetsVisible: ->
  #   # TODO: @pepe needs a better solution or cached
  #   (a for a in @assets when a not in @hidden)

  # assetsFetched: =>
  #   # do after fetch
  #   assets   = []
  #   for asset in @assetsVisible()
  #     try
  #       asset = Asset.get_model(asset).find(asset)
  #     catch error
  #       console.log "Could not find #{asset} in assets list for", @name , @
  #       continue

  #     assets.push(asset)
  #   assets

class Image extends Asset
  @configure 'Image', 'kind', 'name', 'meta', 'path', 'serving_url',
                      'date_created', 'date_modified', 'resolution', 'filesize',
                      'normname', 'canonical'

class Video extends Asset
  @configure 'Video', 'kind', 'name', 'meta', 'path', 'serving_url',
                      'date_created', 'date_modified', 'resolution', 'filesize',
                      'normname', 'canonical', 'formats'

class Generic extends Asset
  @configure 'Generic', 'kind', 'name', 'meta', 'serving_url', 'path',
                        'date_created', 'date_modified', 'normname', 'canonical'

class Proxy extends Asset
  @configure 'Proxy', 'kind', 'name', 'meta', 'path', 'serving_url',
                      'date_created', 'date_modified', 'resolution', 'filesize',
                      'normname', 'proxypath', 'thumb'

class Setting extends Spine.Model

  @configure 'Setting', 'label', 'name', 'value', 'section', 'order',
             'type', 'visible', 'width', 'options'

  @findAllBySection: (section) ->
    settings = @findAllByAttribute('section', section)
    settings.sort((a, b) -> a.order - b.order)
    settings

  @extend Spine.Model.Ajax

Nex.Models =
  Collection: Collection
  Asset     : Asset
  Image     : Image
  Video     : Video
  Proxy     : Proxy
  Setting   : Setting
  Generic   : Generic

module.exports = Nex.Models

