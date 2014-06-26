Nex  = @Nex or require('nex')

class Nex.Widgets.Video extends Spine.Controller
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
    lazy        : true

  events:
    'mousemove'       : 'activateControls'
    'keydown'         : 'activateControls'
    'DOMMouseScroll'  : 'activateControls'
    'mousewheel'      : 'activateControls'
    'mousedown'       : 'activateControls'
    # 'click .playbig'  : 'togglePlay'
    'tap .playbig'    : 'togglePlay'

  elements:
    '.imagowrapper' : 'wrapper'
    'video'         : 'video'

  constructor: ->
    # set default values before init
    for key, value of @defaults
      @[key] = value

    super
    @logPrefix = '(App) Video: '

    @id or= Nex.Utils.uuid()
    @el.data @data if @data

    # convert resolution string to object
    if typeof @resolution is 'string'
      r = @resolution.split('x')
      @resolution =
        width:  r[0]
        height: r[1]
      @assetRatio = r[0]/r[1]

    # play button
    @html """
            <div class="imagowrapper">
              <div class="spin"></div>
              <div class="spin2"></div>
              <a class="playbig fa fa-play" />
              <video></video>
            </div>
          """


    @video = new VideoElement
        el:     @video
        player: @

    @el.addClass "#{@class or ''} #{@size} #{@align} #{@sizemode}"
    # @el.attr('style', @style) if @style

    # create controlbar if video read and if enabled
    if @controls
      @on 'videoready', ->
        @controlBar = new Controls(player: @)
        @wrapper.append @controlBar.el


    # set size of wrapper if provided
    if typeof @width is 'number' and typeof @height is 'number'
      @el.width  @width
      @el.height @height
      # @log 'both number', @width, @height

    # fit width
    else if @height is 'auto' and typeof @width is 'number'
      @height = parseInt @width / @assetRatio
      @el.height @height
      # @log 'fit width', @width, @height

    # fit height
    else if @width is 'auto' and typeof @height is 'number'
      @width = parseInt @height * @assetRatio
      @el.css
        width:  @width
        height: @height
      # @log 'fit height', @width, @height

    # we want dynamic resizing without css.
    # like standard image behaviour. will get a height according to the width
    else if @width is 'auto' and @height is 'auto'
      @width  = parseInt @el.css('width')
      @height = @width / @assetRatio
      @el.height(parseInt @height)
      # @log 'dynamic resizing without css', @width, @height

    # width and height dynamic, needs to be defined via css
    # either width height or position
    else
      @width  = parseInt @el.css('width')
      @height = parseInt @el.css('height')
      @log 'fit width', @width, @height

    @window = $(window)

    # resize video
    @window.on "resize.#{@id}", @resize

    # load poster if enters the viewport
    @window.on "scrollstop.#{@id}", @setupPosterFrame if @lazy

    @delay ->
      # @resize()
      @setupPosterFrame()
      @resize()
    , 330

    @

  resize: =>

    # sizemode crop
    if @sizemode is 'crop'
      width  = @el.width()
      height = @el.height()
      wrapperRatio = width / height
      if @assetRatio < wrapperRatio
        # @log 'full width'
        if Nex.Utils.isiOS()
          s =
            width:  '100%'
            height: '100%'
          if @align is 'center center'
            s.top  = '0'
            s.left = '0'
        else
          s =
            width:  '100%'
            height: 'auto'
          if @align is 'center center'
            s.top  = '50%'
            s.left = 'auto'
            s.marginTop  = "-#{ (width / @assetRatio / 2) }px"
            s.marginLeft = "0px"

        @video.el.css s
        @wrapper.css
          backgroundSize: '100% auto'
          backgroundPosition: @align

      else
        # @log 'full height'
        if Nex.Utils.isiOS()
          s =
            width:  '100%'
            height: '100%'
          if @align is 'center center'
            s.top  = '0'
            s.left = '0'
        else
          s =
            width:  'auto'
            height: '100%'
          if @align is 'center center'
            s.top  = 'auto'
            s.left = '50%'
            s.marginTop  = "0px"
            s.marginLeft = "-#{ (height * @assetRatio / 2) }px"

        @video.el.css s
        @wrapper.css
          backgroundSize: 'auto 100%'
          backgroundPosition: @align

    # sizemode fit
    else
      # @log @el, @el.width(), @el.height()
      width  = @el.width()
      height = @el.height()
      wrapperRatio = width / height
      if @assetRatio > wrapperRatio
        # full width
        # @log 'full width', width, parseInt(width / @assetRatio, 10)
        @video.el.css
          width: '100%'
          height: if Nex.Utils.isiOS() then '100%' else 'auto'
        @wrapper.css
          backgroundSize: '100% auto'
          backgroundPosition: @align
          width:  "#{ width }px"
          height: "#{ parseInt(width / @assetRatio, 10) }px"
      else
        # full height
        # @log 'full height', parseInt(height * @assetRatio, 10), height
        @video.el.css
          width: if Nex.Utils.isiOS() then '100%' else 'auto'
          height: '100%'
        @wrapper.css
          backgroundSize: 'auto 100%'
          backgroundPosition: @align
          width:  "#{ parseInt(height * @assetRatio, 10) }px"
          height: "#{ height }px"

  setupPosterFrame: =>
    return if not ($.inviewport @el, threshold: 0) and @lazy
    return unless !!@src
    # use pvrovided dimentions or current size of @el
    dpr = if @hires then Math.ceil(window.devicePixelRatio) or 1 else 1
    width  = @el.width()
    height = @el.height()

    # width  = 0 unless typeof width  is 'number'
    # height = 0 unless typeof height is 'number'

    @serving_url = @src
    @serving_url += "=s#{ Math.ceil(Math.min(Math.max(width, height) * dpr, 1600)) }"

    css =
      backgroundImage    : "url(#{@serving_url})"
      backgroundPosition : @align
      backgroundRepeat   : 'no-repeat'

    css.backgroundSize  = "auto 100%"
    # css.width           = "#{width}px"  if Number(@width)
    # css.height          = "#{height}px" if Number(@height)

    @wrapper.css css

  activateControls: =>
    return unless @controlBar
    @controlBar.activate()

  play: ->
    @delay @video.play, 500

  pause: =>
    @video.pause()

  stop: =>
    @pause()

  togglePlay: =>
    @video.togglePlay()

module.exports = Nex.Widgets.Video


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

    # @el.empty()
    for format, i in @player.formats
      continue unless codec is format.codec
      src = "//#{Nex.tenant}.imagoapp.com/assets/api/play_redirect?uuid=#{@player.uuid}&codec=#{format.codec}&quality=hd&max_size=#{format.size}"
      srcEl = $('<source />', { src: src, 'data-size': format.size, 'data-codec': format.codec, type: "video/#{codec}"})
      @el.append srcEl

    # @video.load()

  # public functions

  detectCodec: ->
    return unless @el[0].canPlayType

    codecs =
      mp4:  'video/mp4; codecs="mp4v.20.8"'
      mp4:  'video/mp4; codecs="avc1.42E01E"'
      mp4:  'video/mp4; codecs="avc1.42E01E, mp4a.40.2"'
      webm: 'video/webm; codecs="vp8, vorbis"'
      ogg:  'video/ogg; codecs="theora"'

    for key, value of codecs
      if @el[0].canPlayType value
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

  play: =>
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
    # @log 'onended', @player
    @player.trigger 'end'
    @state = 'stopped'

  onvolumechange: (e) ->
    # @log 'onvolumechange'
    @trigger 'volumechange', e

class Controls extends Spine.Controller
  className: 'controls active'

  elements:
    '.time' : 'time'
    '.seek' : 'seek'
    '.volume input' : 'volume'

  events:
    'click  .play'             : 'play'
    'click  .pause'            : 'pause'
    'click  .size'             : 'toggleSize'
    'click  .fullscreen'       : 'onEnterFullScreen'
    'change .seek'             : 'onSeek'
    'change .volume input'     : 'onVolumeChnage'
    'click  .fa-volume-down' : 'muteVolume'
    'click  .fa-volume-up'   : 'fullVolume'

  constructor: ->
    super
    @logPrefix = '(App) Controls: '

    @html """
            <a class="play fa fa-play"></a>
            <a class="pause fa fa-pause"></a>
            <span class="time">00:00</span>
            <span class="seekbar">
              <input type="range" value="0" class="seek"/>
            </span>
            <a class="size">hd</a>
            <span class="volume">
              <span class="fa fa-volume-up"></span>
              <input type="range" value="100"/>
              <span class="fa fa-volume-down"></span>
            </span>
            <a class="fullscreen fa fa-expand"></a>
            <a class="screen fa fa-compress></a>
          """

    @player.video.on 'timeupdate'  , @ontimeupdate
    @player.video.on 'volumechange', @onvolumeupdate

    document.addEventListener(screenfull.raw.fullscreenchange, @onfullscreenchange)

    @activate()

  play: (e) ->
    # e.stopPropagation()
    @player.video.play()
    # @activate()

  pause: (e) ->
    # e.stopPropagation()
    @player.video.pause()

  ontimeupdate: (e) =>
    @time.html @formatTime @player.video.getCurrentTime()
    @seek.val @player.video.getCurrentTime() / @player.video.getEndTime() * 100

  onvolumeupdate: (e) =>
    volume = @player.video.getVolume() * 100
    @volume.val(volume) unless Number(@volume.val()) is volume

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
    # console.log 'onSeek', @player.video.getEndTime()
    value = @player.video.getEndTime() / 100 * $(e.target).val()
    # @log value
    @player.video.seek value

  toggleSize: (e) =>
    # @log 'toggleSize', "from #{ @player.size }"
    if @player.size is 'hd'
      size = 'sd'
    else
      size = 'hd'

    @player.el.addClass(size).removeClass(@player.size)
    @player.size = size
    @player.video.setSize size

  onVolumeChnage: (e) =>
    value = $(e.target).val() / 100
    @player.video.setVolume(value)

  onEnterFullScreen: (e) =>
    return unless screenfull.enabled
    screenfull.request @player.video.el[0]
    @player.video.el[0].setAttribute('controls','controls')

  onfullscreenchange: (e) =>
    @player.video.el[0].removeAttribute('controls') unless screenfull.isFullscreen

  muteVolume: ->
    @player.video.setVolume(0)

  fullVolume: ->
    @player.video.setVolume(1)

  doDelayed: (func, sec) =>
    clearTimeout(@idleTimer) if @idleTimer
    @idleTimer = @delay(func, sec or 2000)

  activate: (e) ->
    @doDelayed(@deactivate)
    @el.addClass('active')

  deactivate: ->
    @el.removeClass('active')

