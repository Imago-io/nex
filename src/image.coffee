class Image extends Spine.Controller
  className: 'imagoimage'

  defaults:
    align     : 'center center'
    sizemode  : 'fit'              # fit, crop
    hires     : true
    scale     : 1
    lazy      : true
    maxSize   : 2000

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

    @id = Nex.Utils.uuid()

    @html '<div class="image"></div><div class="spin"></div><div class="spin2"></div>'

    # set size of wrapper if provided
    @el.width(@width)   if @width
    @el.height(@height) if @height

    @el.addClass(@class)

    @window = $(window)
    # bind to window resize if no dimentions are provided
    if not @width and not @height
      @window.on "resizestop.#{@id}", @preload
    # bind css background size calculation
    @window.on "resize.#{@id}", @resize
    @window.one "scrollstop.#{@id}", @preload if @lazy

    # convert resolution string to object
    if typeof @resolution is 'string'
      r = @resolution.split('x')
      @resolution =
        width:  r[0]
        height: r[1]

    @render()

  render: =>
    return unless @src
    # wait till @el is added to dom

    unless @el.width()
      @delay @render, 250
      return

    @preload()

  resize: =>
    # use pvrovided dimentions or current size of @el
    @image.css('backgroundSize', @calcMediaSize())

  preload: =>
    return if @status is 'preloading'
    return if not ($.inviewport @el, threshold: 0) and @lazy

    @status = 'preloading'

    # use pvrovided dimentions or current size of @el
    # fallback if element is not in dom rendered it has no dimensions yet

    width  =  (@width  * @scale) or @el.width()  or 500
    height =  (@height * @scale) or @el.height() or 500

    # limit size to steps
    # width  = Math.round(width  / 50) * 50 if width
    # height = Math.round(height / 50) * 50 if height


    dpr = if @hires then Math.ceil(window.devicePixelRatio) or 1 else 1
    # servingSize = Math.min(Math[if @sizemode is 'fit' then 'min' else 'max'](width, height) * dpr, @maxSize)

    # sizemode crop
    if @sizemode is 'crop'
      assetRatio = @resolution.width / @resolution.height
      wrapperRatio = width / height
      if assetRatio < wrapperRatio
        # full width
        servingSize = Math.min((Math.round(width / assetRatio) * dpr), @maxSize)
      else
        # full height
        servingSize = Math.min((Math.round(height * assetRatio) * dpr), @maxSize)

    # sizemode fit
    else
      servingSize = Math.min(Math.min(width, height) * dpr, @maxSize)



    # make sure we only load a new size
    if servingSize is @servingSize
      # @log 'abort load. same size', @servingSize, servingSize
      @status = 'loaded'
      return

    @servingSize = servingSize
    @servingUrl = "#{ @src }=s#{ @servingSize }"

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

module.exports = Image