Nex  = @Nex or require('nex')

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
    @el.width(@width)   if @width
    @el.height(@height) if @height

    @el.addClass(@class)
    @el.attr('style', @style) if @style

    @window = $(window)

    # bind to window resize STOP if no dimentions are provided
    @window.on "resizestop.#{@id}", @preload if not @width and not @height

    # bind css background size calculation to window resize START.
    @window.on "resizestart.#{@id}", @resizeStart unless @noResize

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
    unless @el.width()
      @delay @render, 250
      return

    @preload()

  # public
  resize: (width, height) ->
    # return unless width and height and typeof width is 'number' and typeof height is 'number'

    @width  = width
    @height = height

    @el.width  @width
    @el.height @height

    @resizeStart()
    # @preload()

  resizeStart: =>
    # return unless @isActive()
    # use pvrovided dimentions or current size of @el
    @image.css('backgroundSize', @calcMediaSize())

  preload: =>
    # @log 'preload', arguments
    return if not $.inviewport(@el, threshold: 200) if @lazy
    return @log 'tried to preload during preloading!!' if @status is 'preloading'

    # use pvrovided dimentions or current size of @el
    # fallback if element is not in dom rendered it has no dimensions yet
    width  = @width  or @el.width()  or 500
    height = @height or @el.height() or 500

    # limit size to steps
    # width  = Math.round(width  / 50) * 50 if width
    # height = Math.round(height / 50) * 50 if height


    dpr = if @hires then Math.ceil(window.devicePixelRatio) or 1 else 1
    # servingSize = Math.min(Math[if @sizemode is 'fit' then 'min' else 'max'](width, height) * dpr, @maxSize)

    # sizemode crop
    assetRatio   = @resolution.width / @resolution.height

    # only one side of asset is given
    if @width is 'auto'
      wrapperRatio = assetRatio
      @width = width   = height * assetRatio
      @el.width width
      # @log 'width="auto" width: ', width, @width
    else if @height is 'auto'
      wrapperRatio = assetRatio
      @height = height = width / assetRatio
      @el.height height
      # @log 'height="auto" height: ', height, @height
    else
      wrapperRatio = width / height

    return if not ($.inviewport @el, threshold: 100) and @lazy

    # unbind scrollstop listener for lazy loading
    @window.off "scrollstop.#{@id}" if @lazy


    @status = 'preloading'

    if @sizemode is 'crop'
      if assetRatio <= wrapperRatio
        # @log 'full width'
        servingSize = Math.round(Math.max(width, width / assetRatio))
      else
        # @log 'full height'
        servingSize = Math.round(Math.max(height, height * assetRatio))

    # sizemode fit
    else
      # @log 'ratios', assetRatio, wrapperRatio
      if assetRatio <= wrapperRatio
        # @log 'full height', width, height
        servingSize = Math.round(Math.max(height, height * assetRatio))
      else
        # @log 'full width', width, height
        servingSize = Math.round(Math.max(width, width / assetRatio))

    servingSize = Math.min(servingSize * dpr, @maxSize)



    # make sure we only load a new size
    if servingSize is @servingSize
      # @log 'abort load. same size', @servingSize, servingSize
      @status = 'loaded'
      return

    @servingSize = servingSize
    # @log @servingSize * @scale
    @servingUrl = "#{ @src }=s#{ @servingSize * @scale }"

    # create image and bind load event
    img = $('<img>').bind 'load', @imgLoaded
    img.attr('src', @servingUrl)

    css =
      # backgroundImage    : "url(#{@servingUrl})"
      backgroundPosition : "center center" or @align
      display            : "inline-block"

    css.backgroundSize  = @calcMediaSize()
    css.width           = "#{parseInt @width,  10}px"  if Number(@width)
    css.height          = "#{parseInt @height, 10}px" if Number(@height)

    @image.css(css)

  imgLoaded: =>
    @trigger 'loaded'
    @status = 'loaded'

    # @align = 'center center' unless @align
    # @log 'imgLoaded', @width, @height

    css =
      backgroundImage    : "url(#{@servingUrl})"
    #   backgroundPosition : "center center" or @align
    #   display            : "inline-block"

    # css.backgroundSize  = @calcMediaSize()
    # css.width           = "#{parseInt @width,  10}px"  if Number(@width)
    # css.height          = "#{parseInt @height, 10}px" if Number(@height)

    @el.removeClass('loaded')
    @image.css(css)

    @delay @loadedClass, 1

  calcMediaSize: =>
    # @log 'calcMediaSize'
    width  =  @width  or @el.width()
    height =  @height or @el.height()
    assetRatio = @resolution.width / @resolution.height
    wrapperRatio = width / height
    if @sizemode is 'crop'
      # @log '@sizemode crop', assetRatio, wrapperRatio
      if assetRatio < wrapperRatio then "100% auto" else "auto 100%"
    else
      if assetRatio > wrapperRatio then "100% auto" else "auto 100%"

  loadedClass: ->
    @el.addClass('loaded')

  activate: ->
    @preload()

  release: ->
    # @log 'release'
    @window.off @id
    super

module.exports = Nex.Widgets.Image