class Video extends Spine.Controller
  className: 'imagovideo'

  defaults:
    autobuffer  : null
    autoplay    : false
    controls    : true
    preload     : 'none'
    # keyShortcut : true
    size        : 'hd'
    align       : 'left top'
    sizemode    : 'fit'

  events:
    'mousemove'       : 'activateControls'
    'keydown'         : 'activateControls'
    'DOMMouseScroll'  : 'activateControls'
    'mousewheel'      : 'activateControls'
    'mousedown'       : 'activateControls'
    # 'click .playbig'  : 'togglePlay'
    'tap .playbig'    : 'togglePlay'

  constructor: ->
    # set default values before init
    for key, value of @defaults
      @[key] = value

    super
    @logPrefix = '(App) Video: '

    @append @videoEl = new VideoElement(player: @)
    @video = @videoEl.video

    @el.addClass "#{@class or ''} #{@size} #{@align} #{@sizemode}"

    # play button
    @append @playbig = $('<div class="spin"></div><div class="spin2"></div><a class="playbig icon-play" />')

    # create controlbar if video read and if enabled
    @on 'videoready', -> @append @controlBar = new Controls(player: @) if @controls


    # set size of wrapper if provided
    @el.width(@width)   if @width
    @el.height(@height) if @height

    w = $(window).on 'resize', @resize

    # convert resolution string to object
    if typeof @resolution is 'string'
      r = @resolution.split('x')
      @resolution =
        width:  r[0]
        height: r[1]

    @delay ->
      @resize()
      @setupPosterFrame()
      @resize()
    , 330

    @

  resize: =>
    assetRatio   = @resolution.width / @resolution.height

    # sizemode crop
    if @sizemode is 'crop'
      width  = @width  or @el.width()
      height = @height or @el.height()
      wrapperRatio = width / height
      if assetRatio < wrapperRatio
          # full width
        s =
          width: '100%'
          height: 'auto'
        if @align is 'center center'
          s.top  = '50%'
          s.left = 'auto'
          s.marginTop  = "-#{ (width / assetRatio / 2) }px"
          s.marginLeft = "0px"
        @videoEl.el.css s
        @el.css
          backgroundSize: '100% auto'
          backgroundPosition: @align

      else
        # full height
        s =
          width: 'auto'
          height: '100%'
        if @align is 'center center'
          s.top  = 'auto'
          s.left = '50%'
          s.marginTop  = "0px"
          s.marginLeft = "-#{ (height * assetRatio / 2) }px"
        @videoEl.el.css s
        @el.css
          backgroundSize: 'auto 100%'
          backgroundPosition: @align

    # sizemode fit
    else
      width  = @width  or @el.parent().width()
      height = @height or @el.parent().height()
      wrapperRatio = width / height
      if assetRatio > wrapperRatio
        # full width
        @videoEl.el.css
          width: '100%'
          height: 'auto'
        @el.css
          backgroundSize: '100% auto'
          backgroundPosition: @align
          width:  "#{ width }px"
          height: "#{ width / assetRatio }px"
      else
        # full height
        @videoEl.el.css
          width: 'auto'
          height: '100%'
        @el.css
          backgroundSize: 'auto 100%'
          backgroundPosition: @align
          width:  "#{ height * assetRatio }px"
          height: "#{ height }px"

  setupPosterFrame: ->
    # @log 'setupPosterFrame'
    # use pvrovided dimentions or current size of @el
    dpr = if @hires then Math.ceil(window.devicePixelRatio) or 1 else 1
    width  = @width  or @el.width()
    height = @height or @el.height()

    @serving_url = @src
    @serving_url += "=s#{ Math.ceil(Math.min(Math.max(width, height) * dpr, 1600)) }"

    css =
      backgroundImage    : "url(#{@serving_url})"
      backgroundPosition : @align

    css.backgroundSize  = "auto 100%"
    css.width           = "#{width}px"  if Number(@width)
    css.height          = "#{height}px" if Number(@height)

    @el.css css

  activateControls: =>
    return unless @controlBar
    @controlBar.activate()

  play: ->
    @delay @videoEl.play, 500

  pause: =>
    @videoEl.pause()

  stop: =>
    @pause()

  togglePlay: =>
    @videoEl.togglePlay()

module.exports = Video


class VideoElement extends Spine.Controller
  tag: 'video'

  events:
    'click'           : 'click'
    'dblclick'        : 'dblclick'
    'error'           : 'onerror'
    'loadstart'       : 'onloadstart'
    'loadeddata'      : 'onloadeddata'
    'progress'        : 'onprogress'
    'canplay'         : 'oncanplay'
    'durationchange'  : 'ondurationchange'
    'timeupdate'      : 'ontimeupdate'
    'pause'           : 'onpause'
    'play'            : 'onplay'
    'ended'           : 'onended'
    'volumechange'    : 'onvolumechange'

  constructor: ->
    super
    @logPrefix = '(App) VideoElement: '

    @codecs  = ['mp4', 'webm']
    @video = @el[0]

    @el.attr
      autoplay:   @player.autoplay
      preload:    @player.preload
      autobuffer: @player.autobuffer
      'x-webkit-airplay':    'allow'
      webkitAllowFullscreen: 'true'

    @loadSources()

  loadSources: ->
    return unless @player.uuid
    codec = @detectCodec()
    @player.formats.sort( (a, b) -> return b.height - a.height )

    @el.empty()
    for format, i in @player.formats
      continue unless codec is format.codec
      src = "http://#{Spine.settings.tenant}.imagoapp.com/assets/api/play_redirect?uuid=#{@player.uuid}&codec=#{format.codec}&quality=hd&max_size=#{format.size}"
      srcEl = $('<source />', { src: src, 'data-size': format.size, 'data-codec': format.codec, type: "video/#{codec}"})
      @el.append srcEl

    # @video.load()

  # public functions

  detectCodec: ->
    tag = document.createElement 'video'
    return unless tag.canPlayType

    codecs =
      mp4:  'video/mp4; codecs="mp4v.20.8"'
      mp4:  'video/mp4; codecs="avc1.42E01E"'
      mp4:  'video/mp4; codecs="avc1.42E01E, mp4a.40.2"'
      webm: 'video/webm; codecs="vp8, vorbis"'
      ogg:  'video/ogg; codecs="theora"'

    for key, value of codecs
      if tag.canPlayType value
        return key

  setSize: (size) ->
    time = @getCurrentTime()
    srcs = @el.children('source')
    return unless srcs.length > 1

    poster = @player.el.css('backgroundImage')
    @player.el.css('backgroundImage', '')

    @el.one 'loadeddata', =>
      @seek time
      @el.css('display', 'block')
      @player.el.css('backgroundImage', poster)
      @play()

    @pause()
    @el.css('display', 'none')
    @el.attr 'src', srcs[(if size is "hd" then 0 else srcs.length - 1)].src
    @video.load()

  play: ->
    @video.play()

  pause: ->
    @video.pause()

  seek: (offset) ->
    state = @state
    @pause()
    @setCurrentTime offset
    @play() if state is 'playing'

  setCurrentTime: (offset) ->
    @video.currentTime offset

  togglePlay: ->
    # @log 'togglePlay', @state
    if @state is 'playing'
      @pause()
    else
      @play()

  getDuration: ->
    @video.duration

  getStartTime: ->
    @video.startTime or 0

  getEndTime: ->
    if @video.duration is Infinity and @video.buffered
      @video.buffered.end @video.buffered.length - 1
    else
      (@video.startTime or 0) + @video.duration

  getCurrentTime: ->
    try
      return @video.currentTime
    catch e
      return 0

  setCurrentTime: (val) ->
    @video.currentTime = val

  getVolume: ->
    @video.volume

  setVolume: (val) ->
    @video.volume = val

  enterFullScreen: (e) ->
    # @log 'enterFullScreen', e
    @video.webkitEnterFullScreen()

  exitFullScreen: ->
    # @log 'exitFullScreen'


  # event functions
  click: =>
    # @log 'click'
    @togglePlay()

  dblclick: =>
    # @log 'dblclick'

  onerror: (e) =>
    @log 'onerror', e

  onprogress: =>
    @player.el.addClass 'loading'
    # @log 'onprogress'

  onloadeddata: =>
    # @log 'onloadeddata'
    @player.el.removeClass 'loading'
    @player.trigger 'videoready'

  onloadstart: =>
    # @log 'onloadstart'

  oncanplay: =>
    # @log 'oncanplay'
    @player.el.removeClass 'loading'

  ondurationchange: =>
    # @log 'ondurationchange'

  ontimeupdate: (e) ->
    # @log 'ontimeupdate'
    @trigger 'timeupdate', e

  onpause: =>
    # @log 'onpause'
    @state = 'paused'
    @player.el.removeClass 'playing'

  onplay: =>
    # @log 'onplay'
    @state = 'playing'
    @player.el.addClass 'playing'
    @player.el.removeClass 'loading'
    # @log @state, @

  onended: =>
    # @log 'onended'
    @state = 'stopped'

  onvolumechange: (e) ->
    # @log 'onvolumechange'
    @trigger 'timeupdate', e


class Controls extends Spine.Controller
  className: 'controls active'

  elements:
    '.time' : 'time'
    '.seek' : 'seek'
    '.volume input' : 'volume'

  events:
    'click .play'           : 'play'
    'click .pause'          : 'pause'
    'change .seek'          : 'onSeek'
    'click .size'           : 'toggleSize'
    'change .volume input'  : 'onVolumeChnage'
    'click .fullscreen'     : 'onEnterFullScreen'

  constructor: ->
    super
    @logPrefix = '(App) Controls: '

    @html '<a class="play icon-play"></a><a class="pause icon-pause"></a><span class="time">00:00</span><span class="seekbar"><input type="range" value="0" class="seek"/></span><a class="size">hd</a><span class="volume"><span class="icon-volume-up"></span><input type="range" value="100"/><span class="icon-volume-down"></span></span><a class="fullscreen icon-resize-full"></a><a class="screen icon-resize-small"></a>'

    @player.videoEl.on 'timeupdate', @ontimeupdate

    @activate()

  play: (e) ->
    # e.stopPropagation()
    @player.videoEl.play()
    # @activate()

  pause: (e) ->
    # e.stopPropagation()
    @player.videoEl.pause()

  ontimeupdate: (e) =>
    @time.html @formatTime @player.videoEl.getCurrentTime()
    @seek.val @player.videoEl.getCurrentTime() / @player.videoEl.getEndTime() * 100

  pad: (num) ->
    return "0" + num  if num < 10
    num

  formatTime: (sec) ->
    result = []
    minutes = Math.floor(sec / 60)
    hours = Math.floor(sec / 3600)
    seconds = (if (sec is 0) then 0 else (sec % 60))
    seconds = Math.round(seconds)
    result.push @pad(hours)  if hours > 0
    result.push @pad(minutes)
    result.push @pad(seconds)
    result.join ":"

  onSeek: (e) =>
    # console.log 'onSeek', @player.videoEl.getEndTime()
    value = @player.videoEl.getEndTime() / 100 * $(e.target).val()
    # @log value
    @player.videoEl.seek value

  toggleSize: (e) =>
    # @log 'toggleSize', "from #{ @player.size }"
    if @player.size is 'hd'
      size = 'sd'
    else
      size = 'hd'

    @player.el.addClass(size).removeClass(@player.size)
    @player.size = size
    @player.videoEl.setSize size

  onVolumeChnage: (e) =>
    value = $(e.target).val() / 100
    @player.videoEl.setVolume(value)

  onEnterFullScreen: (e) =>
    # @log 'onEnterFullScreen', screenfull.enabled
    return unless screenfull.enabled
    screenfull.request @player.video
    # @player.videoEl.video.webkitEnterFullScreen()

  doDelayed: (func, sec) =>
    clearTimeout(@idleTimer) if @idleTimer
    @idleTimer = @delay(func, sec or 2000)

  activate: (e) ->
    @doDelayed(@deactivate)
    @el.addClass('active')

  deactivate: ->
    @el.removeClass('active')
