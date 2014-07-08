Nex = @Nex or require('nex')
_ = require('underscore')

class Nex.Widgets.Image extends Spine.Controller
  className: 'imagoimage'

  defaults:
    align     : 'center center'
    sizemode  : 'fit'              # fit, crop
    hires     : true
    scale     : 1
    lazy      : true
    maxSize   : 2560
    # noResize  : false deprecated
    mediasize : false
    width     : ''
    height    : ''
    responsive: true

  events:
    'resize' : 'render'

  elements:
    '.imagox23' : 'image'

  constructor: ->
    # set default values before init
    for key, value of @defaults
      @[key] = value

    if @noResize
      @log '@noResize depricated will be removed soon, use responsive: false'
      @responsive = false

    super
    @logPrefix = '(App) Image: '

    # check requirements
    return @log 'Error: image widget rquires src' unless @src
    return @log 'Error: image widget rquires resolution' unless @resolution

    @id or= Nex.Utils.uuid()
    @el.data @data if @data

    @html '<div class="imagox23"></div><div class="spin"></div><div class="spin2"></div>'

    # set size of wrapper if provided
    @el.width(@width)   if typeof @width  is 'number'
    @el.height(@height) if typeof @height is 'number'

    @el.addClass(@class)
    @el.attr('style', @style) if @style

    @window = $(window)

    # bind to window resize STOP if no dimentions are provided
    @window.on "resizestop.#{@id}", @preload if @responsive

    # bind css background size calculation to window resize START.
    @window.on "resize.#{@id}", _.throttle(@onResize, 250) if @responsive

    # load image if enters the viewport
    @window.on "scrollstop.#{@id}", @preload if @lazy

    # convert resolution string to object
    if typeof @resolution is 'string'
      r = @resolution.split('x')
      @resolution =
        width:  r[0]
        height: r[1]

    @render()

  render: =>
    # wait till @el is added to dom
    return if @released
    unless @el.width() or @el.height()
      # @log 'el not ready delay render for 250ms', @width, @height
      @delay @render, 250
      return

    @preload()

  # public function
  resize: (width, height) ->
    # return unless width and height and typeof width is 'number' and typeof height is 'number'
    @width  = width  if width
    @height = height if height

    # @el.width  @width
    # @el.height @height

    @onResize()

  onResize: =>
    # return unless @isActive()
    @image.css('backgroundSize', @calcMediaSize())

  preload: (options) =>
    # @log 'preload', @width, @height

    for key, value of options
      @[key] = value

    @onResize()

    return @log 'tried to preload during preloading!!' if @status is 'preloading'
    # @log 'preloading :', width, @width, height, @height

    # Abort if not in viewport
    # if not $.inviewport(@el, threshold: 0) and @lazy
    #   # @log 'in viewport: ', $.inviewport(@el, threshold: 0)
    #   return

    # sizemode crop
    assetRatio = @resolution.width / @resolution.height

    # use pvrovided dimentions.
    if typeof @width is 'number' and typeof @height is 'number'
      # @log 'fixed size', width, height

    # fit width
    else if @height is 'auto' and typeof @width is 'number'
      @height = parseInt @width / assetRatio
      @el.height @height

      # @log 'fit width', @width, @height

    # fit height
    else if @width is 'auto' and typeof @height is 'number'
      @width = parseInt @height * assetRatio
      @el.width @width
      # @log 'fit height', @width, @height

    # we want dynamic resizing without css.
    # like standard image behaviour. will get a height according to the width
    else if @width is 'auto' and @height is 'auto'
      @width  = parseInt @el.css('width')
      @height = @width / assetRatio
      @el.height(parseInt @height)
      # @log 'both auto', width, height

    # width and height dynamic, needs to be defined via css
    # either width height or position
    else
      @width  = parseInt @el.css('width')
      @height = parseInt @el.css('height')

      # @log 'fit el', @width, @height


    # check viewport here
    if not $.inviewport(@el, threshold: 0) and @lazy
      # @log 'in viewport: ', $.inviewport(@el, threshold: 0)
      return

    # @log 'width, height', width, height

    # this should only be done if imageimage is not pos absolute
    # @el.height height if @el.css('position') in ['static', 'relative']

    @status = 'preloading'

    # unbind scrollstop listener for lazy loading
    @window.off "scrollstop.#{@id}" if @lazy

    wrapperRatio = @width / @height

    dpr = if @hires then Math.ceil(window.devicePixelRatio) or 1 else 1
    # servingSize = Math.min(Math[if @sizemode is 'fit' then 'min' else 'max'](width, height) * dpr, @maxSize)

    # @log 'width, height', width, height
    if @sizemode is 'crop'
      if assetRatio <= wrapperRatio
        # @log 'crop full width'
        servingSize = Math.round(Math.max(@width, @width / assetRatio))
      else
        # @log 'crop full height', @height, @width, assetRatio, wrapperRatio
        servingSize = Math.round(Math.max(@height, @height * assetRatio))

    # sizemode fit
    else
      # @log 'ratios', assetRatio, wrapperRatio
      if assetRatio <= wrapperRatio
        # @log 'fit full height', @width, @height, assetRatio, @height * assetRatio
        servingSize = Math.round(Math.max(@height, @height * assetRatio))
      else
        # @log 'fit full width', @width, @height, assetRatio, @height / assetRatio
        servingSize = Math.round(Math.max(@width, @width / assetRatio))

    servingSize = parseInt Math.min(servingSize * dpr, @maxSize)
    # @log 'servingSize', servingSize, @width, @height, dpr, @maxSize

    # make sure we only load a new size
    if servingSize is @servingSize
      # @log 'abort load. same size', @servingSize, servingSize
      @status = 'loaded'
      return

    @servingSize = servingSize
    # @log @servingSize * @scale
    @servingUrl = "#{ @src }=s#{ parseInt(@servingSize * @scale) }"

    # @log 'servingURl', @servingUrl

    # create image and bind load event
    img = $('<img>').bind 'load', @imgLoaded
    img.attr('src', @servingUrl)

    css = {}
    css.backgroundPosition = @align
    css.display            = "inline-block"

    #Only apply witdh and height if responsive is false
    unless @responsive
      css.width  = "#{parseInt @width,  10}px"
      css.height = "#{parseInt @height, 10}px"

    @image.css(css)
    @el.removeClass('loaded')

  imgLoaded: =>
    @image.css
      backgroundImage : "url(#{@servingUrl})"
      backgroundSize  : @calcMediaSize()

    @delay ->
      @el.addClass('loaded')
    , 250

    @trigger 'loaded'
    @status = 'loaded'

  calcMediaSize: (options) =>
    for key, value of options
      @[key] = value

    # @log 'calcMediaSize', @sizemode
    @width  = @el.width()  or @width
    @height = @el.height() or @height
    # @log 'calcMediaSize: @width, @height', @width, @height
    return unless @width and @height
    assetRatio = @resolution.width / @resolution.height
    wrapperRatio = @width / @height
    if @sizemode is 'crop'
      # @log '@sizemode crop', assetRatio, wrapperRatio
      if assetRatio < wrapperRatio then "100% auto" else "auto 100%"
    else
      # @log '@sizemode fit', assetRatio, wrapperRatio
      if assetRatio > wrapperRatio then "100% auto" else "auto 100%"


  setBackgroundSize: (options) =>
    for key, value of options
      @[key] = value

    # @log 'calcMediaSize', @sizemode
    @width  or= @el.width()
    @height or= @el.height()
    # @log 'calcMediaSize: width, height', width, height
    assetRatio = @resolution.width / @resolution.height
    wrapperRatio = @width / @height
    if @sizemode is 'crop'
      # @log '@sizemode crop', assetRatio, wrapperRatio
      if assetRatio < wrapperRatio then value = "100% auto" else value = "auto 100%"
    else
      # @log '@sizemode fit', assetRatio, wrapperRatio
      if assetRatio > wrapperRatio then value = "100% auto" else value = "auto 100%"

    @image.css backgroundSize : value

  activate: ->
    super
    @preload()

  release: ->
    @window.off @id if @id
    @released = true
    super

module.exports = Nex.Widgets.Image
