// Generated by CoffeeScript 1.6.3
(function() {
  var alphaNumSort, alphanum, cookie, normalize, queryfy, requestAnimationFrame, sha, urlify, uuid;

  requestAnimationFrame = (function() {
    var request;
    request = window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(callback) {
      return window.setTimeout(callback, 1000 / 60);
    };
    return function(callback) {
      return request.call(window, callback);
    };
  })();

  cookie = function(name, value) {
    var _i, _len, _ref;
    if (!value) {
      _ref = document.cookie.split(';');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cookie = _ref[_i];
        if (cookie.indexOf(name) === 1) {
          return cookie.split('=')[1];
        }
      }
      return false;
    }
    return document.cookie = "" + name + "=" + value + "; path=/";
  };

  sha = function() {
    var i, possible, text, _i;
    text = '';
    possible = 'abcdefghijklmnopqrstuvwxyz0123456789';
    for (i = _i = 0; _i <= 56; i = ++_i) {
      text += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return text;
  };

  uuid = function() {
    var S4;
    S4 = function() {
      return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    };
    return S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4();
  };

  urlify = function(query) {
    return console.log('urlify');
  };

  queryfy = function(url) {
    var facet, filter, key, query, value, _i, _len, _ref;
    query = [];
    _ref = url.split('+');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      filter = _ref[_i];
      filter || (filter = 'collection:/');
      facet = filter.split(':');
      key = facet[0].toLowerCase();
      value = decodeURIComponent(facet[1] || '');
      facet = {};
      facet[key] = value;
      query.push(facet);
    }
    return query;
  };

  normalize = function(s) {
    var mapping, r, str;
    mapping = {
      'ä': 'ae',
      'ö': 'oe',
      'ü': 'ue',
      '&': 'and',
      'é': 'e',
      'ë': 'e',
      'ï': 'i',
      'è': 'e',
      'à': 'a',
      'ù': 'u',
      'ç': 'c',
      'ø': 'o'
    };
    s = s.toLowerCase();
    r = new RegExp(Object.keys(mapping).join('|'), 'g');
    str = s.trim().replace(r, function(s) {
      return mapping[s];
    }).toLowerCase();
    return str.replace(/[',:;#]/g, '').replace(/[^\/\w]+/g, '-').replace(/\W?\/\W?/g, '\/').replace(/^-|-$/g, '');
  };

  alphaNumSort = alphanum = function(a, b) {
    var aa, bb, c, chunkify, d, x;
    chunkify = function(t) {
      var i, j, m, n, tz, x, y;
      tz = [];
      x = 0;
      y = -1;
      n = 0;
      i = void 0;
      j = void 0;
      while (i = (j = t.charAt(x++)).charCodeAt(0)) {
        m = i === 46 || (i >= 48 && i <= 57);
        if (m !== n) {
          tz[++y] = "";
          n = m;
        }
        tz[y] += j;
      }
      return tz;
    };
    aa = chunkify(a);
    bb = chunkify(b);
    x = 0;
    while (aa[x] && bb[x]) {
      if (aa[x] !== bb[x]) {
        c = Number(aa[x]);
        d = Number(bb[x]);
        if (c === aa[x] && d === bb[x]) {
          return c - d;
        } else {
          return (aa[x] > bb[x] ? 1 : -1);
        }
      }
      x++;
    }
    return aa.length - bb.length;
  };

  module.exports = {
    requestAnimationFrame: requestAnimationFrame,
    cookie: cookie,
    sha: sha,
    uuid: uuid,
    urlify: urlify,
    queryfy: queryfy,
    normalize: normalize,
    alphaNumSort: alphaNumSort
  };

}).call(this);

/*
//@ sourceMappingURL=utils.map
*/