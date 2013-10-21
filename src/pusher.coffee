Nex  = @Nex or require('nex')

Nex.Pusher =

  dispatch_message: (msg) ->
    message = if typeof msg is 'string' then JSON.parse(msg) else msg
    methods =
      update_proxy       : @proxy @_update_proxy
      serving_url_change : @proxy @_serving_url_change
      add                : @proxy @_add
      delete             : @proxy @_delete
      switch_ids         : @proxy @_swith_ids

    methods[message.action](message)

  parse_data: (data, options = {ajax : false}) ->
    for asset in data
      continue unless asset
      # console.log 'asset is', asset
      if asset.kind == 'Collection'
        existing = @globalExists(asset.id)
        if existing
          tgllist   = @_diffresult(asset.hidden, existing.hidden)
          assetchng = @_diffresult(asset.assets, existing.assets)
          adds      = (i for i in assetchng when i not in existing.assets)
          deletes   = (i for i in assetchng when i not in asset.assets)
          if not assetchng.length
            orderchange = @_orderdiff(existing.assets, asset.assets)
      item = @create_or_update(asset, options)

      if tgllist?
        for id in tgllist
          @globalExists(id)?.trigger 'visibility.tile', collection: item.id

      if deletes?.length
        assets = (asset for asset in (@globalExists(id) for id in deletes) when asset)
        item.trigger 'delete.assets', assets if assets.length

      if adds?.length
        @_triggeradds(adds, item)

      item.trigger 'update.assets' if orderchange?.length

  _triggeradds: (assetids, collection) ->
    @get(ids: assetids).done( (result) =>
      if assetids.length > result.items.length
        toCreate = (i for i in assetids when i not in (x.id for x in result.items))
        newObjs = []
        for id in toCreate
          kind = if id.indexOf('Col') != 0 then 'Upload' else 'Collection'
          attrs =
              id     : id
              kind   : kind
              name   : 'Processing'
              meta   : {}

          if kind is 'Collection'
              attrs.assets = []
              attrs.hidden = []
          elem = @get_model(id).create(attrs, {ajax:false})
          newObjs.push(elem)

        result.items = result.items.concat(newObjs)
        result.count = result.items.length
      # sort the elems based on the collections order
      result.items.sort( (a, b) => collection.assets.indexOf(a.id) - collection.assets.indexOf(b.id) )
      result.items.reverse() # reverse the result to prepend them in the right order

      collection.trigger 'add.assets', result.items if result.count > 0
      )

  _diffresult: (a, b) ->
    result = (i for i in a when i not in b)
    result.concat((i for i in b when i not in a))

  _orderdiff: (listA, listB) ->
    listA.filter((item, idx, list) ->
      return idx != listB.indexOf(item)
    )

  _update_proxy: (message) ->
    @get(ids : message.ids, false)

  _serving_url_change: (message) ->
    asset = @globalFind(message.id)
    if asset and asset.count() < message.count
      @get(ids : [message.id])
    else if asset and message.s_url and asset.serving_url != message.s_url
      asset.serving_url = message.s_url
      asset.save(ajax:false)
    else if not asset
      @get(ids : [message.id], false)

  _add: (message) ->
    if message.data
      @parse_data(message.data)
    else
      @getSearch(ids : [message.id])
        .done((data, status, xhr) =>
          @parse_data(data)
        )

  _delete: (message) ->
    asset = @globalExists(message.id)
    asset?.destroy(ajax: false)

  _swith_ids: (message) ->
    # VideoModel      = @get_model('Video')
    CollectionModel = @get_model('Collection')
    asset = @globalExists(message.from_id)
    return unless asset
    return if message.to_id == message.from_id
    if @globalExists(message.to_id)
      # the destination video is already in the system
      p_holder = asset
      asset    = @globalFind(message.to_id)
      cols     = CollectionModel.select((col) -> p_holder.id in col.assets)
      for col in cols
        col.assets.splice(col.assets.indexOf(p_holder.id), 1, asset.id)
        if col.serving_url?.indexOf('http://') < 0
          col.serving_url = asset.serving_url
        col.save()
        col.trigger 'add.assets', [asset.id]
        col.trigger 'delete.assets', [p_holder.id]
      p_holder.destroy(ajax:false)
    else
      asset.changeID(message.to_id, {ajax:false})
      cols     = CollectionModel.select((col) -> message.from_id in col.assets)
      for col in cols
        if col and message.from_id in col.assets
          col.assets.splice(col.assets.indexOf(message.from_id), 1, asset.id)
          col.hidden.splice(col.assets.indexOf(message.from_id), 1, asset.id)
          col.save()
    asset.save(ajax: false)

module.exports = Nex.Pusher