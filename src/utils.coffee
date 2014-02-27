Nex  = @Nex or require('nex')

KEYS =
  '16'  : 'onShift'
  '18'  : 'onAlt'
  '17'  : 'onCommand'
  '91'  : 'onCommand'
  '93'  : 'onCommand'
  '224' : 'onCommand'
  '13'  : 'onEnter'
  '32'  : 'onSpace'
  '37'  : 'onLeft'
  '38'  : 'onUp'
  '39'  : 'onRight'
  '40'  : 'onDown'
  '46'  : 'onDelete'
  '8'   : 'onBackspace'
  '9'   : 'onTab'
  '188' : 'onComma'
  '190' : 'onPeriod'
  '27'  : 'onEsc'
  '186' : 'onColon'
  '65'  : 'onA'
  '67'  : 'onC'
  '86'  : 'onV'
  '88'  : 'onX'
  '68'  : 'onD'
  '187' : 'onEqual'
  '189' : 'onMinus'

SYMBOLS =
  EUR     : '&#128;'
  USD     : '&#36;'
  SEK     : 'SEK'
  GENERIC : '&#164;'

Nex.Utils =

  requestAnimationFrame: do ->
    request =
      window.requestAnimationFrame or
      window.webkitRequestAnimationFrame or
      window.mozRequestAnimationFrame or
      window.oRequestAnimationFrame or
      window.msRequestAnimationFrame or
      (callback) ->
        window.setTimeout(callback, 1000 / 60)

    (callback) ->
      request.call(window, callback)

  cookie: (name, value) ->
    unless value
      # get cookie
      for cookie in document.cookie.split(';')
        if cookie.indexOf(name) == 1
          return cookie.split('=')[1]
      return false
    # set cookie
    document.cookie = "#{name}=#{value}; path=/"

  sha: ->
    text = ''
    possible = 'abcdefghijklmnopqrstuvwxyz0123456789'

    for i in [0..56]
      text += possible.charAt(Math.floor(Math.random() * possible.length))

    text

  uuid: ->
    S4 = ->
      (((1+Math.random())*0x10000)|0).toString(16).substring(1)

    (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4())

  urlify: (query) ->
    console.log 'urlify'

  queryfy: (url) ->
    query = []

    for filter in url.split('+')
      filter or= 'collection:/'

      facet = filter.split(':')
      key   = facet[0].toLowerCase()
      value = decodeURIComponent(facet[1] or '')

      facet = {}
      facet[key] = value
      query.push(facet)

    query

  pluralize: (str) ->
    str + 's'

  singularize: (str) ->
    str.replace(/s$/, '')

  normalize: (s) ->
    mapping =
      'ä': 'ae'
      'ö': 'oe'
      'ü': 'ue'
      '&': 'and'
      'é': 'e'
      'ë': 'e'
      'ï': 'i'
      'è': 'e'
      'à': 'a'
      'ù': 'u'
      'ç': 'c'
      'ø': 'o'

    s = s.toLowerCase()
    r = new RegExp(Object.keys(mapping).join('|'), 'g')
    str = s.trim().replace(r, (s) -> mapping[s]).toLowerCase()

    str.replace(/[',:;#]/g, '').replace(/[^\/\w]+/g, '-').replace(/\W?\/\W?/g, '\/').replace(/^-|-$/g, '')

  alphaNumSort: alphanum = (a, b) ->
    chunkify = (t) ->
      tz = []
      x = 0
      y = -1
      n = 0
      i = undefined
      j = undefined
      while i = (j = t.charAt(x++)).charCodeAt(0)
        m = (i is 46 or (i >= 48 and i <= 57))
        if m isnt n
          tz[++y] = ""
          n = m
        tz[y] += j
      tz
    aa = chunkify(a)
    bb = chunkify(b)
    x = 0
    while aa[x] and bb[x]
      if aa[x] isnt bb[x]
        c = Number(aa[x])
        d = Number(bb[x])
        if c is aa[x] and d is bb[x]
          return c - d
        else
          return (if (aa[x] > bb[x]) then 1 else -1)
      x++
    aa.length - bb.length

  isiOS: ->
    return !!navigator.userAgent.match(/iPad|iPhone|iPod/i)

  isiPad: ->
    return !!navigator.userAgent.match(/iPad/i)

  isiPhone: ->
    return !!navigator.userAgent.match(/iPhone/i)

  isiPod: ->
    return !!navigator.userAgent.match(/iPod/i)

  isChrome: ->
    return !!navigator.userAgent.match(/Chrome/i)

  isIE: ->
    return !!navigator.userAgent.match(/MSIE/i)

  isFirefox: ->
    return !!navigator.userAgent.match(/Firefox/i)

  isOpera: ->
    return !!navigator.userAgent.match(/Presto/i)

  isSafari: ->
    return !!navigator.userAgent.match(/Safari/i) and not @isChrome()

  isEven: (n) ->
    return @isNumber(n) and (n % 2 is 0)

  isOdd: (n) ->
    return @isNumber(n) and (n % 2 is 1)

  isNumber: (n) ->
    return n is parseFloat(n)

  toFloat: (value, decimal=2) ->
    value   = String(value).replace(/\D/g, '')
    floats  = value.slice(value.length - decimal)

    # add trailing zeros
    floats = '0' + floats while floats.length < decimal
    ints   = value.slice(0, value.length - decimal) or '0'

    return "#{ints}.#{floats}"

  toPrice: (value, currency) ->
    price  = @toFloat(value).replace(/(\d)(?=(\d{3})+\.)/g, '$1,')
    symbol = @getCurrencySymbol(currency)
    "#{symbol} #{price}"

  isEmail: (value) ->
    pattern = ///^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$///
    return !!value.match(pattern)

  getAssetKind: (id) ->
    if id.indexOf('Collection-') is 0
      kind = 'Collection'
    else if id.indexOf('Proxy-') is 0
      kind = 'Proxy'
    else if id.indexOf('Order-') is 0
      kind = 'Order'
    else if id.indexOf('Generic') is 0
      kind = 'Generic'
    else if id.match /[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}/
      kind = 'Image'
    else if id.match /[0-9a-z]{56}/
      kind = 'Video'
    return kind

  getKeyName: (e) ->
    KEYS[e.which]

  getURLParameter: (name) ->
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
    regex = new RegExp("[\\?&]" + name + "=([^&#]*)")
    results = regex.exec(location.search)
    (if not results? then "" else decodeURIComponent(results[1].replace(/\+/g, " ")))

  inUsa: (value) ->
    value?.toLowerCase() in ['usa', 'united states', 'united states of america']

  getCurrencySymbol: (currency) ->
    SYMBOLS[currency] or SYMBOLS.GENERIC

module.exports = Nex.Utils