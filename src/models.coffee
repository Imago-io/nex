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
    if @meta[field]?.value?.hasOwnProperty('value')
      return @meta[field].value?.value or fallback
    @meta[field]?.value or fallback

  options: ->
    # the options available for this asset
    opts = {}
    for variant in @variants
      for key, obj of variant.meta
        key = Nex.Utils.pluralize(key)
        opts[key] or= []
        opts[key].push(obj.value) if obj.value not in opts[key]
    opts

  discounted: ->
    (@variants[0].meta.discounted) and \
    ((@variants[0].meta.discounted.value > 0) or \
    (@variants[0].meta.discounted.value[Nex.currency] > 0))


  related: (params) ->
    params.uuid    = @id
    params.limit or= 10
    params.related = @getMeta(params.propname, [])
    Asset.get(params)


class Collection extends Asset
  @configure 'Collection', 'kind', 'name', 'meta', 'path', 'serving_url', 'variants',
                           'date_created', 'date_modified', 'resolution', 'sort_by',
                           'sort_order', 'assets', 'hidden', 'normname', 'canonical'


class Image extends Asset
  @configure 'Image', 'kind', 'name', 'meta', 'path', 'serving_url', 'variants',
                      'date_created', 'date_modified', 'resolution', 'filesize',
                      'normname', 'canonical'

class Video extends Asset
  @configure 'Video', 'kind', 'name', 'meta', 'path', 'serving_url', 'variants',
                      'date_created', 'date_modified', 'resolution', 'filesize',
                      'normname', 'canonical', 'formats'

class Generic extends Asset
  @configure 'Generic', 'kind', 'name', 'meta', 'serving_url', 'path',
                        'date_created', 'date_modified', 'resolution',
                        'normname', 'canonical', 'variants'

class Proxy extends Asset
  @configure 'Proxy', 'kind', 'name', 'meta', 'path', 'serving_url', 'variants',
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


class Member extends Spine.Model
  @configure 'Member', 'email', 'first_name', 'last_name'

  @getMember: ->
    deferred = $.Deferred()
    promise  = deferred.promise()

    successResponse = (data, status, xhr, options) =>
      # update the local records with the newly
      # fetched assets via fetch_asse
      member = if data.email then @create(data) else undefined
      deferred.resolve(member)

    # fetch variants via ajax
    $.ajax(
      contentType: 'application/json'
      dataType: 'json'
      processData: false
      headers: Spine.Ajax.defaults
      type: 'GET'
      url:  '/api/v2/member'
    ).success(successResponse)
     .error(-> deferred.resolve())

    promise

  @login: ->
    @_axaxCall('POST', {action : 'loginurl'})

  @logout: ->
    @_axaxCall('POST', {action : 'logouturl'})

  @checkout: ->
    @_axaxCall('POST', {action : 'checkout'})

  @_axaxCall: (type, data) ->
    deferred = $.Deferred()
    promise  = deferred.promise()

    $.ajax(
      contentType: 'application/json'
      dataType: 'json'
      processData: false
      headers: Spine.Ajax.defaults
      type: type
      data: JSON.stringify(data)
      url:  '/api/v2/member'
    ).success((data, status, xhr, options) ->
      if data.url
        window.location = data.url
      else
        deferred.resolve(data)
    ).error(-> console.log 'error')

    promise


class CartItem extends Spine.Model
  @configure 'CartItem', 'meta', 'serving_url', 'quantity', 'price',
                                 'color', 'size', 'itemid', 'headline', 'description'


  @addToCart: (itemid, quantity, options={'size':'', 'color':'', headline:'', description:''}) ->
    # console.log 'optoins are', options
    existing = @select((item) -> item.itemid is itemid)
    if existing.length
      item = existing[0]
      item.quantity = item.quantity + quantity
      item.save()
      return

    item =
      itemid      : itemid
      quantity    : quantity
      color       : options?.color
      size        : options?.size
      serving_url : options?.serving_url
      price       : options?.price
      headline    : options?.headline
      description : options?.description
    @create(item)


  @extend Spine.Model.Ajax

Spine.Ajax.defaults.headers['NexClient'] = Nex.client

Nex.Models =
  Collection: Collection
  Asset     : Asset
  Image     : Image
  Video     : Video
  Proxy     : Proxy
  Setting   : Setting
  Generic   : Generic
  Member    : Member
  CartItem  : CartItem

module.exports = Nex.Models