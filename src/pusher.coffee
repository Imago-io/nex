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
          console.log 'in successResponse adds:', adds.length, 'deletes', deletes.length
      item = @create_or_update(asset, options)

      if tgllist?
        for id in tgllist
          @globalExists(id)?.trigger 'visibility.tile'

      if deletes?.length
        assets = (asset for asset in (@globalExists(id) for id in deletes) when asset)
        console.log 'assets', assets.length
        item.trigger 'delete.assets', assets if assets.length

      item.trigger 'add.assets', adds if adds?.length
      item.trigger 'update.assets' if orderchange?.length

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

  _delete: (message) =>
    # console.log 'delete message', message
    asset = @globalFind(message.id)
    asset.destroy(ajax: false)

  _swith_ids: (message) ->
    # VideoModel      = @get_model('Video')
    CollectionModel = @get_model('Collection')
    asset = @globalExists(message.from_id)
    return unless asset
    if @globalExists(message.to_id)
      # the destination video is already in the system
      p_holder = asset
      asset    = @globalFind(message.to_id)
      cols     = CollectionModel.select((col) -> p_holder.id in col.assets)
      for col in cols
        col.assets.splice(p_holder.id, 1, asset.id)
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
          col.assets.splice(message.from_id, 1, asset.id)
          col.hidden.splice(message.from_id, 1, asset.id)
          col.save(ajax:false)
    asset.save(ajax: false)

module.exports = Nex.Pusher