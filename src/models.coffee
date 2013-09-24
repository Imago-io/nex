Search = require("./search")

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


class CartItem extends Spine.Model
  @configure 'CartItem', 'headline', 'description', 'serving_url',
                         'quantity', 'taxable', 'price', 'weight', 'itemid'


  @addToCart: (itemid, quantity) ->
    existing = @select((item) -> item.itemid is itemid)
    if existing.length
      cartitem = existing[0]
      cartitem.quantity = cartitem.quantity + quantity
    else
      cartitem = new @({'itemid':itemid, 'quantity': quantity})

    cartitem.save()


  @extend Spine.Model.Ajax



Nex.Models =
  Collection: Collection
  Asset     : Asset
  Image     : Image
  Video     : Video
  Proxy     : Proxy
  Setting   : Setting
  Generic   : Generic
  CartItem  : CartItem

module.exports = Nex.Models