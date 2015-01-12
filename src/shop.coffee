Nex = @Nex or require('nex')
_ = require('underscore')

class Nex.Widgets.Shop extends Spine.Controller

  logPrefix: '(App) ShopWidget: '
  className: 'shopWidget'

  elements:
    '.wrapper' : 'wrapper'
    '.error'            : 'error'
    '.price'            : 'price'

  events:
    'tap .add'          : 'addToCart'

  constructor: ->
    super

    @tmpl = require('views/shop')

    @controllers = []

    @item = {}

    @render()

  render: ->
    @clear()

    variant = @getVariant()

    @html @tmpl
      asset: @asset
      variant: variant
      onSale: if variant and variant.meta.discounted?.value[Nex.currency] then variant.meta.discounted else false
      href:  window.location.href
      Nex :  Nex

    for opt in @options
      @add @[opt] = new Option
        name: opt
        item: @item
        asset: @asset

      @listenTo @[opt], 'update', @update
      @listenTo @[opt], 'dropdown', @closeOptions

  add: (controller) ->
    @controllers.push controller
    @wrapper.append controller.el

  update: (params) =>
    @item[params.key] = params.value
    @render()

  getVariant: =>
    return false unless _.keys(@item).length is @options.length
    variant = _.filter @asset.variants, (variant) =>
      status = true
      for key, value of @item
        key = Nex.Utils.singularize(key)
        status = false unless variant.meta[key].value is value
      return status

    return variant[0]

  closeOptions: (option) =>
    for controller in @controllers
      continue if controller.name is option or controller.open is false
      controller.toggleDropdown()

  clear: ->
    for controller in @controllers
      controller.release()
    @stopListening()

  release: ->
    @clear()
    super

  addToCart: =>
    variant = @getVariant()
    if not variant
      return @error.html 'please choose size and color'
    else if variant.meta.stock?.value is 0
      return @error.html 'sorry, out of stock'

    if variant.meta.discounted
      price = variant.meta.discounted.value
    else
      price = variant.meta.price.value

    product =
      serving_url : variant.meta.serving_url?.value or @asset.serving_url
      price:  price
      headline: @asset.getMeta('title', '')
      description : @asset.getMeta('description', '')

    for key, value of @item
      key = Nex.Utils.singularize(key)
      product[key] = value

    Nex.Models.CartItem.addToCart(variant.id, 1, product)

module.exports = Nex.Widgets.Shop

class Option extends Spine.Controller

  logPrefix: '(App) option: '
  className: 'option select'

  events:
    'tap'        : 'toggleDropdown'
    'tap .choice': 'update'

  constructor: ->
    super

    @tmpl = require('views/option')
    @el.addClass(@name)

    @opts = @asset.options()[@name]

    @open = false

    @render()

  render: ->

    @html @tmpl
      name:  @name
      item: @item
      options: @opts
      checkOption: @checkOption

    $('body').on 'tap', @globalClick

  checkOption: (option) =>

    status =
      notAvailable: false
      soldOut: false
      onSale: false

    # filter all asset variants
    variants = _.filter @asset.variants, (variant) =>
      passed = true
      name = Nex.Utils.singularize(@name)
      #check if the variant contains this option
      unless variant.meta[name].value is option
        passed = false
      #Unless @item is empty filter the variants by the options in @item
      unless _.isEmpty(@item)
        for key, value of @item
          #Don't filter the variants by this selection's option
          continue if key is @name
          key = Nex.Utils.singularize(key)
          unless variant.meta[key].value is value
            passed = false

      return passed

    #If no variants are found return not available
    if variants.length is 0
      status.notAvailable = true
    else
      totalStock = 0
      for variant in variants
        totalStock += variant.meta.stock.value or 0
        #if any of the variants are discounted return onSale
        if variant.meta.discounted and variant.meta.discounted?.value[Nex.currency] > 0
          status.onSale = true
          continue
      #if totalStock of the variants is 0 return soldOut
      unless totalStock > 0
        status.soldOut = true

    return status

  toggleDropdown: (e) =>
    @open = !@open
    @el.toggleClass('active', @open)
    @trigger('dropdown', @name) if @open

  update: (e) ->
    data =
      key:  @name
      value: $(e.target).data('value')
    @trigger 'update', data

  globalClick: (e) =>
    target = $(e.target)
    if not target.closest('.option').length and @open
      @toggleDropdown()
