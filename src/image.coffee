class Image extends Spine.Controller
  className: 'imagoimage'

  defaults:
    align     : 'center center'
    sizemode  : 'fit'              # fit, crop
    hires     : true
    scale     : 1

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

    @html '<div class="image"></div><div class="spin"></div><div class="spin2"></div>'

    # set size of wrapper if provided
    @el.width(@width)   if @width
    @el.height(@height) if @height

    @el.addClass(@class)

    w = $(window)
    # bind to window resize if no dimentions are provided
    if not @width and not @height
      w.on 'resizestop', @preload
    # bind css background size calculation
    w.on 'resize', @resize

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

    return unless @src
    @preload()

  resize: =>
    # use pvrovided dimentions or current size of @el
    @image.css('backgroundSize', @calcMediaSize())

  preload: =>
    return if @status is 'preloading'
    @status = 'preloading'

    # use pvrovided dimentions or current size of @el
    # fallback if element is not in dom rendered it has no dimensions yet
    width  =  (@width  * @scale) or @el.width()  or 500
    height =  (@height * @scale) or @el.height() or 500

    # @log 'real', width, @width, @el.width()

    # limit size to steps
    width  = Math.round(width  / 50) * 50 if width
    height = Math.round(height / 50) * 50 if height

    # @log 'rounded', width, height

    dpr = if @hires then Math.ceil(window.devicePixelRatio) or 1 else 1
    @serving_url = @src
    @serving_url += "=s#{ Math.min(Math.max(width, height) * dpr, 1600) }"
    # @serving_url += "-c" if @sizemode is 'crop'
    @serving_url += "-w#{width  * dpr}" if Number(width)
    @serving_url += "-h#{height * dpr}" if Number(height)

    # @log '@serving_url', @serving_url

    # create image and bind load event
    img = $('<img>').bind 'load', @imgLoaded
    img.attr('src', @serving_url)

    # @log 'preloading', @serving_url.split('=')[@serving_url.split('=').length - 1]


  imgLoaded: =>
    @trigger 'loaded'
    @status = 'loaded'

    @align = 'center center' unless @align
    # @log 'align', @align

    css =
      backgroundImage    : "url(#{@serving_url})"
      backgroundPosition : @align
      display            : "inline-block"

    css.backgroundSize  = @calcMediaSize()
    css.width           = "#{@width}px"  if Number(@width)
    css.height          = "#{@height}px" if Number(@height)

    @el.removeClass('loaded')
    @image.css(css)

    @delay @loadedClass, 500

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

module.exports = Image