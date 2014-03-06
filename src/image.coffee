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
    noResize  : false
    mediasize : false
    width     : 'auto'
    height    : 'auto'

  events:
    'resize' : 'render'

  elements:
    '.image' : 'image'

  constructor: ->
    # set default values before init
    for key, value of @defaults
      @[key] = value

    super
    @logPrefix = '(App) Image: '

    # check requirements
    return @log 'Error: image widget rquires src' unless @src
    return @log 'Error: image widget rquires resolution' unless @resolution

    @id = Nex.Utils.uuid()

    @html '<div class="image"></div><div class="spin"></div><div class="spin2"></div>'

    # set size of wrapper if provided
    @el.width(@width)   if typeof @width  is 'number'
    @el.height(@height) if typeof @height is 'number'

    @el.addClass(@class)
    @el.attr('style', @style) if @style

    @window = $(window)

    # bind to window resize STOP if no dimentions are provided
    @window.on "resizestop.#{@id}", @preload if @lazy #or !@noResize

    # bind css background size calculation to window resize START.
    @window.on "resize.#{@id}", _.throttle(@onResize, 250) unless @noResize

    # load image if enters the viewport
    @window.on "scrollstop.#{@id}", @preload if @lazy #or !@noResize

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

  preload: (options = {}) =>

    width    = options.width    or @width
    height   = options.height   or @height
    sizemode = options.sizemode or @sizemode

    return @log 'tried to preload during preloading!!' if @status is 'preloading'
    # @log 'preloading :', width, @width, height, @height

    # Abort if not in viewport
    # if not $.inviewport(@el, threshold: 0) and @lazy
    #   # @log 'in viewport: ', $.inviewport(@el, threshold: 0)
    #   return

    # @el.removeClass('loaded')

    #use new sizemode if it is passed as an argument
    @sizemode = sizemode unless sizemode is @sizemode

    # sizemode crop
    assetRatio = @resolution.width / @resolution.height

    # use pvrovided dimentions or current size of @el
    if width is @width or width is 'auto' and height is @height or height is 'auto'
      # fixed size asset, we have with and height
      # @log 'IfElse Block: ', width, @width, height, @height
      if typeof @width is 'number' and typeof @height is 'number'
        # @log 'fixed size', @width, @height
        width = @width
        height = @height

      # fit width
      else if @height is 'auto' and typeof @width is 'number'
        # @log 'fit width', @width, @height
        width = @width
        height = @width * assetRatio
        @el.height(height)

      # fit height
      else if @width is 'auto' and typeof @height is 'number'
        # @log 'fit height', @width, @height
        height = @height
        width = @height * assetRatio
        @el.width(width)

      # width and height dynamic, needs to be defined via css
      # either width height or position
      else
        # @log 'dynamic height and width', @width, @height
        width  = parseInt @el.css('width')
        height = parseInt @el.css('height')

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

    wrapperRatio = width / height
    # @log 'width, height, wrapperRatio', width, height, wrapperRatio
    # debugger

    dpr = if @hires then Math.ceil(window.devicePixelRatio) or 1 else 1
    # servingSize = Math.min(Math[if @sizemode is 'fit' then 'min' else 'max'](width, height) * dpr, @maxSize)

    # @log 'width, height', width, height
    if @sizemode is 'crop'
      if assetRatio <= wrapperRatio
        # @log 'crop full width'
        servingSize = Math.round(Math.max(width, width / assetRatio))
      else
        # @log 'crop full height'
        servingSize = Math.round(Math.max(height, height * assetRatio))

    # sizemode fit
    else
      # @log 'ratios', assetRatio, wrapperRatio
      if assetRatio <= wrapperRatio
        # @log 'fit full height', width, height, assetRatio, height * assetRatio
        servingSize = Math.round(Math.max(height, height * assetRatio))
      else
        # @log 'fit full width', width, height, assetRatio, height / assetRatio
        servingSize = Math.round(Math.max(width, width / assetRatio))

    servingSize = Math.min(servingSize * dpr, @maxSize)
    # @log 'servingSize', servingSize, width, height



    # make sure we only load a new size
    if servingSize is @servingSize
      # @log 'abort load. same size', @servingSize, servingSize
      @status = 'loaded'
      return

    @servingSize = servingSize
    # @log @servingSize * @scale
    @servingUrl = "#{ @src }=s#{ @servingSize * @scale }"

    # @log 'servingURl', @servingUrl

    # create image and bind load event
    img = $('<img>').bind 'load', @imgLoaded
    img.attr('src', @servingUrl)

    css =
      # backgroundImage    : "url(#{@servingUrl})"
      backgroundPosition : @align
      display            : "inline-block"

    # @log 'width, height', width, height
    #Only apply witdh and height if a fixed size is requested
    css.width           = "#{parseInt width,  10}px" if typeof @width  is 'number'
    css.height          = "#{parseInt height, 10}px" if typeof @height is 'number'

    # @log 'css', css

    @image.css(css)

  imgLoaded: =>
    @el.removeClass('loaded')

    @image.css
      backgroundImage : "url(#{@servingUrl})"
      backgroundSize  : @calcMediaSize()


    @delay ->
      @el.addClass('loaded')
    , 250

    @trigger 'loaded'
    @status = 'loaded'

  calcMediaSize: (options = {}) =>

    @sizemode = options.sizemode if options.sizemode

    # @log 'calcMediaSize', @sizemode
    width  =  +@width  or @el.width()
    height =  +@height or @el.height()
    # @log 'calcMediaSize: width, height', width, height
    assetRatio = @resolution.width / @resolution.height
    wrapperRatio = width / height
    if @sizemode is 'crop'
      # @log '@sizemode crop', assetRatio, wrapperRatio
      if assetRatio < wrapperRatio then "100% auto" else "auto 100%"
    else
      # @log '@sizemode fit', assetRatio, wrapperRatio
      if assetRatio > wrapperRatio then "100% auto" else "auto 100%"


  setBackgroundSize: (options = {}) =>

    @sizemode = options.sizemode if options.sizemode

    # @log 'calcMediaSize', @sizemode
    width  =  +@width  or @el.width()
    height =  +@height or @el.height()
    # @log 'calcMediaSize: width, height', width, height
    assetRatio = @resolution.width / @resolution.height
    wrapperRatio = width / height
    if @sizemode is 'crop'
      # @log '@sizemode crop', assetRatio, wrapperRatio
      if assetRatio < wrapperRatio then value = "100% auto" else value = "auto 100%"
    else
      # @log '@sizemode fit', assetRatio, wrapperRatio
      if assetRatio > wrapperRatio then value = "100% auto" else value = "auto 100%"

    @image.css backgroundSize  : value

  activate: ->
    super
    @preload()

  release: ->
    @window.off @id
    @released = true
    super

module.exports = Nex.Widgets.Image