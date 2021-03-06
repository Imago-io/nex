// Generated by CoffeeScript 1.6.3
(function() {
  var KEYS, getKeyName;

  KEYS = {
    '16': 'shift',
    '18': 'alt',
    '17': 'command',
    '91': 'command',
    '93': 'command',
    '224': 'command',
    '13': 'enter',
    '37': 'left',
    '38': 'up',
    '39': 'right',
    '40': 'down',
    '46': 'delete',
    '8': 'backspace',
    '9': 'tab',
    '188': 'comma',
    '190': 'period',
    '27': 'esc',
    '186': 'colon',
    '65': 'aKey',
    '67': 'cKey',
    '86': 'vKey',
    "88": 'xKey'
  };

  getKeyName = function(e) {
    return KEYS[e.which];
  };

  module.exports = getKeyName;

}).call(this);

/*
//@ sourceMappingURL=keys.map
*/
