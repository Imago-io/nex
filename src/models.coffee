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

  @models: ->
    models =
      Collection : Nex.Models.Collection
      Image      : Nex.Models.Image
      Video      : Nex.Models.Video
      Proxy      : Nex.Models.Proxy
      Generic    : Nex.Models.Generic
    return models

  @filter: (callback, exclude = []) ->
    models  = @models()
    exclude = if Spine.isArray(exclude) then exclude else [exclude]
    results   = []
    for modelName of models
      if modelName in exclude
        continue
      results = results.concat(models[modelName].select(callback))
    results

  @create_or_update: (attrs, options) ->
    model = @get_model(attrs.id)
    return model.create(attrs, options) unless model.exists(attrs.id)
    model.update(attrs.id, attrs, options)

  @related: (params) ->
    params.context = if params.context.id then params.context.id else params.context
    params.limit or= 10
    params.related = context.getMeta?(params.propname, [])
    @get(params)


  _normalizeValue: (value) ->
    return '' if not value
    value = value.value if value.hasOwnProperty('value')
    if Spine.isArray(value)
      normalized = (Nex.Utils.normalize(val) for val in value)
      value.push val for val in normalized when val not in value
    value = value.join(' ').toLowerCase() if Spine.isArray(value)
    value = value.toLowerCase() if typeof value == "string"
    return value

  query: (params, searchkey=undefined) ->
    # full text serach.
    attributes = (key for key of @meta)
    for key in attributes
      continue if searchkey and (searchkey isnt key)
      value = @_normalizeValue(@meta[key].value)
      for q in params
        result = value.indexOf?(q)
        continue if result is undefined
        return true if result != -1
    return false

  related: (params) ->
    params.context = @
    Asset.related(params)

  getMeta: (field, fallback='') ->
    return fallback unless field

    if @meta[field]?.value?.hasOwnProperty('value')
      value = @meta[field]?.value.value
    else
      value = @meta[field]?.value

    # cover proxy asset
    if @meta[field]?.original_value?.hasOwnProperty('value')
      original_value = @meta[field]?.original_value.value
    else
      original_value = @meta[field]?.original_value

    return value or original_value or fallback

  options: ->
    # the options available for this asset
    opts = {}
    for variant in @variants
      for key, obj of variant.meta
        key = Nex.Utils.pluralize(key)
        opts[key] or= []
        opts[key].push(obj.value) if obj.value and obj.value not in opts[key]
    opts

  filterOptions: (keyname, value) ->
    # return available options based on existing key/value pair
    variants = @variants.filter((item) ->
                  item.meta[Nex.Utils.singularize(keyname)]?.value is value
                )
    opts = {
      mapping : {}
    }
    for variant in variants
      for key, obj of variant.meta
        key = Nex.Utils.pluralize(key)
        opts[key] or= []
        opts[key].push(obj.value) if obj.value not in opts[key]
        opts.mapping[obj.value] = variant.meta.stock?.value or 0
    opts

  discounted: (index=0)->
    return false unless @variants.length
    (@variants[index].meta.discounted) and \
    ((@variants[index].meta.discounted.value > 0) or \
    (@variants[index].meta.discounted.value[Nex.currency] > 0))


  totalStock: ->
    return 100 unless @variants.length
    (v.meta.stock?.value for v in @variants).reduce (t, s) -> t + s

  price: (currency, discounted=false, decimals=true) ->
    currency or= Nex.currency
    priceValue = @variants[0]?.meta.price.value[currency] or \
                 @getMeta('price', {currency: 0})[currency]
    if discounted
      priceValue = @variants[0]?.meta.discounted.value[currency] or \
                   @getMeta('discounted', {currency: 0})[currency]
    Nex.Utils.toPrice(priceValue, currency, decimals)

  upvote: ->
    @meta.likes or= value: 0
    @meta.likes.value++
    @meta.likes.liked = true
    @save()
    successResponse = (data, status, xhr, options) =>
      # update the local records with the newly
      # fetched assets via fetch_asse

    host = if (Nex.data is 'online' and Nex.debug) then "http://#{Nex.tenant}.imagoapp.com" else ""

    # fetch variants via ajax
    $.ajax(
      contentType : 'application/json'
      dataType    : 'json'
      processData : false
      data        : JSON.stringify({'likes' : {'value' : @meta.likes.value}})
      type        : 'PUT'
      url         : host + '/api/v2/metaupdate/' + @id
    ).success(successResponse)
     .error(-> @log 'error while upvoting')

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

  @findByName: (name) ->
    @findByAttribute('name', name)

  @ensureCurrency: ->
    return if Nex.currency is Nex.Utils.cookie 'currency'
    Nex.Utils.cookie 'currency', Nex.currency
    jqxhr = $.ajax "/api/v2/cart",
      type: "POST"
      data: JSON.stringify(currency: Nex.currency)

  @currency: ->
    sessioncur = Nex.Utils.getCurrencyByCode(Nex.country)
    currencies = @findByName('currencies').value
    if sessioncur in currencies then sessioncur else currencies[0]


  @setSessionData: ->
    Nex.currencies = @findByName('currencies')?.value
    Nex.ipaddress  = @findByName('ipaddress')?.value
    Nex.country    = @findByName('country')?.value
    Nex.city       = @findByName('city')?.value
    Nex.region     = @findByName('region')?.value
    Nex.currency   = @currency()
    $.ajax(
      type: 'GET'
      url:  'http://geoip.nekudo.com/api/'
    ).success((data) =>
        Nex.country  = data.country.code
        Nex.city     = data.city
        Nex.region   = ''
        Nex.currency = @currency()
      )
     .error(-> console?.log 'fetch error for geoip')



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
    Setting.ensureCurrency()
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
    ).error(-> console?.log 'error')

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