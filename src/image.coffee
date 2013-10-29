Nex  = @Nex or require('nex')

class Nex.Widgets.Image extends Spine.Controller
  className: 'imagoimage'

  defaults:
    align     : 'center center'
    sizemode  : 'fit'              # fit, crop
    hires     : true
    scale     : 1
    lazy      : true
    maxSize   : 2000
    noResize  : false

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
    return throw new Error 'image widget rquires src' unless @src
    return throw new Error 'image widget rquires resolution' unless @resolution

    @id = Nex.Utils.uuid()

    @html '<div class="image"></div><div class="spin"></div><div class="spin2"></div>'

    # set size of wrapper if provided
    @el.width(@width)   if @width
    @el.height(@height) if @height

    @el.addClass(@class)
    @el.attr('style', @style) if @style

    @window = $(window)
    # bind to window resize if no dimentions are provided
    if not @width and not @height
      @window.on "resizestop.#{@id}", @preload
    # bind css background size calculation
    @window.on "resize.#{@id}", @resize
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

  resize: =>
    # @log 'resize'
    return if @noResize
    # use pvrovided dimentions or current size of @el
    @image.css('backgroundSize', @calcMediaSize())

  preload: =>
    # @log $.inviewport(@el, threshold: 0)
    return if @status is 'preloading'
    return if not ($.inviewport @el, threshold: 0) and @lazy

    @status = 'preloading'

    # use pvrovided dimentions or current size of @el
    # fallback if element is not in dom rendered it has no dimensions yet

    width  =  @width  or @el.width()  or 500
    height =  @height or @el.height() or 500

    # limit size to steps
    # width  = Math.round(width  / 50) * 50 if width
    # height = Math.round(height / 50) * 50 if height


    dpr = if @hires then Math.ceil(window.devicePixelRatio) or 1 else 1
    # servingSize = Math.min(Math[if @sizemode is 'fit' then 'min' else 'max'](width, height) * dpr, @maxSize)

    # sizemode crop
    assetRatio = @resolution.width / @resolution.height
    wrapperRatio = width / height
    if @sizemode is 'crop'
      if assetRatio < wrapperRatio
        # @log 'full width'
        servingSize = Math.round(Math.max(width, width / assetRatio))
      else
        # @log 'full height'
        servingSize = Math.round(Math.max(height, height * assetRatio))

    # sizemode fit
    else
      # @log 'ratios', assetRatio, wrapperRatio
      if assetRatio < wrapperRatio
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
    @log @servingSize * @scale
    @servingUrl = "#{ @src }=s#{ @servingSize * @scale }"

    # create image and bind load event
    img = $('<img>').bind 'load', @imgLoaded
    img.attr('src', @servingUrl)


  imgLoaded: =>
    @trigger 'loaded'
    @status = 'loaded'

    @align = 'center center' unless @align
    # @log 'align', @align

    css =
      backgroundImage    : "url(#{@servingUrl})"
      backgroundPosition : @align
      display            : "inline-block"

    css.backgroundSize  = @calcMediaSize()
    css.width           = "#{@width}px"  if Number(@width)
    css.height          = "#{@height}px" if Number(@height)

    @el.removeClass('loaded')
    @image.css(css)

    @delay @loadedClass, 1

  calcMediaSize: =>
    width  =  @width  or @el.width()
    height =  @height or @el.height()
    assetRatio = @resolution.width / @resolution.height
    wrapperRatio = width / height
    if @sizemode is 'crop'
      if assetRatio < wrapperRatio then "100% auto" else "auto 100%"
    else
      if assetRatio > wrapperRatio then "100% auto" else "auto 100%"

  loadedClass: ->
    @el.addClass('loaded')

  release: ->
    @window.off @id
    super

module.exports = Nex.Widgets.Image