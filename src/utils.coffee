Nex  = @Nex or require('nex')

requestAnimationFrame = do ->
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


cookie = (name, value) ->
  unless value
    # get cookie
    for cookie in document.cookie.split(';')
      if cookie.indexOf(name) == 1
        return cookie.split('=')[1]
    return false
  # set cookie
  document.cookie = "#{name}=#{value}; path=/"

sha = ->
  text = ''
  possible = 'abcdefghijklmnopqrstuvwxyz0123456789'

  for i in [0..56]
    text += possible.charAt(Math.floor(Math.random() * possible.length))

  text

uuid = ->
  S4 = ->
    (((1+Math.random())*0x10000)|0).toString(16).substring(1)

  (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4())

urlify = (query) ->
  console.log 'urlify'

queryfy = (url) ->
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

normalize = (s) ->
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

alphaNumSort = alphanum = (a, b) ->
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

isiOS = ->
  return !!navigator.userAgent.match(/iPad|iPhone|iPod/i)

isiPad = ->
  return !!navigator.userAgent.match(/iPad/i)

isiPhone = ->
  return !!navigator.userAgent.match(/iPhone/i)

isiPod = ->
  return !!navigator.userAgent.match(/iPod/i)

isChrome = ->
  return !!navigator.userAgent.match(/Chrome/i)

isIE = ->
  return !!navigator.userAgent.match(/MSIE/i)

isFirefox = ->
  return !!navigator.userAgent.match(/Firefox/i)

isOpera = ->
  return !!navigator.userAgent.match(/Presto/i)

isSafari = ->
  return !!navigator.userAgent.match(/Safari/i) and not @isChrome()

Nex.Utils =
  requestAnimationFrame : requestAnimationFrame
  cookie                : cookie
  sha                   : sha
  uuid                  : uuid
  urlify                : urlify
  queryfy               : queryfy
  normalize             : normalize
  alphaNumSort          : alphaNumSort
  isiOS                 : isiOS
  isiPad                : isiPad
  isiPhone              : isiPhone
  isiPod                : isiPod
  isChrome              : isChrome
  isIE                  : isIE
  isFirefox             : isFirefox
  isOpera               : isOpera
  isSafari              : isSafari

module.exports = Nex.Utils