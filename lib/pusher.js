// Generated by CoffeeScript 1.6.3
(function() {
  var Nex,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    _this = this;

  Nex = this.Nex || require('nex');

  Nex.Pusher = {
    dispatch_message: function(msg) {
      var message, methods;
      message = typeof msg === 'string' ? JSON.parse(msg) : msg;
      methods = {
        update_proxy: this.proxy(this._update_proxy),
        serving_url_change: this.proxy(this._serving_url_change),
        add: this.proxy(this._add),
        "delete": this.proxy(this._delete),
        switch_ids: this.proxy(this._swith_ids)
      };
      return methods[message.action](message);
    },
    parse_data: function(data, options) {
      var adds, asset, assetchng, assets, deletes, existing, i, id, item, orderchange, tgllist, _i, _j, _len, _len1, _ref, _results;
      if (options == null) {
        options = {
          ajax: false
        };
      }
      _results = [];
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        asset = data[_i];
        if (!asset) {
          continue;
        }
        if (asset.kind === 'Collection') {
          existing = this.globalExists(asset.id);
          if (existing) {
            tgllist = this._diffresult(asset.hidden, existing.hidden);
            assetchng = this._diffresult(asset.assets, existing.assets);
            adds = (function() {
              var _j, _len1, _results1;
              _results1 = [];
              for (_j = 0, _len1 = assetchng.length; _j < _len1; _j++) {
                i = assetchng[_j];
                if (__indexOf.call(existing.assets, i) < 0) {
                  _results1.push(i);
                }
              }
              return _results1;
            })();
            deletes = (function() {
              var _j, _len1, _results1;
              _results1 = [];
              for (_j = 0, _len1 = assetchng.length; _j < _len1; _j++) {
                i = assetchng[_j];
                if (__indexOf.call(asset.assets, i) < 0) {
                  _results1.push(i);
                }
              }
              return _results1;
            })();
            if (!assetchng.length) {
              orderchange = this._orderdiff(existing.assets, asset.assets);
            }
          }
        }
        item = this.create_or_update(asset, options);
        if (tgllist != null) {
          for (_j = 0, _len1 = tgllist.length; _j < _len1; _j++) {
            id = tgllist[_j];
            if ((_ref = this.globalExists(id)) != null) {
              _ref.trigger('visibility.tile');
            }
          }
        }
        if (deletes != null ? deletes.length : void 0) {
          assets = (function() {
            var _k, _len2, _ref1, _results1;
            _ref1 = (function() {
              var _l, _len2, _results2;
              _results2 = [];
              for (_l = 0, _len2 = deletes.length; _l < _len2; _l++) {
                id = deletes[_l];
                _results2.push(this.globalExists(id));
              }
              return _results2;
            }).call(this);
            _results1 = [];
            for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
              asset = _ref1[_k];
              if (asset) {
                _results1.push(asset);
              }
            }
            return _results1;
          }).call(this);
          if (assets.length) {
            item.trigger('delete.assets', assets);
          }
        }
        if (adds != null ? adds.length : void 0) {
          this._triggeradds(adds, item);
        }
        if (orderchange != null ? orderchange.length : void 0) {
          _results.push(item.trigger('update.assets'));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    },
    _triggeradds: function(assetids, collection) {
      var _this = this;
      return this.get({
        ids: assetids
      }).done(function(result) {
        var attrs, elem, i, id, kind, newObjs, toCreate, x, _i, _len;
        if (assetids.length > result.items.length) {
          toCreate = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = assetids.length; _i < _len; _i++) {
              i = assetids[_i];
              if (__indexOf.call((function() {
                var _j, _len1, _ref, _results1;
                _ref = result.items;
                _results1 = [];
                for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
                  x = _ref[_j];
                  _results1.push(x.id);
                }
                return _results1;
              })(), i) < 0) {
                _results.push(i);
              }
            }
            return _results;
          })();
          newObjs = [];
          for (_i = 0, _len = toCreate.length; _i < _len; _i++) {
            id = toCreate[_i];
            kind = id.indexOf('Col') !== 0 ? 'Upload' : 'Collection';
            attrs = {
              id: id,
              kind: kind,
              name: 'Processing',
              meta: {}
            };
            if (kind === 'Collection') {
              attrs.assets = [];
              attrs.hidden = [];
            }
            elem = _this.get_model(i).create(attrs, {
              ajax: false
            });
            newObjs.push(elem);
          }
          result.items = result.items.concat(newObjs);
          result.count = result.items.length;
        }
        result.items.sort(function(a, b) {
          return collection.assets.indexOf(a.id) - collection.assets.indexOf(b.id);
        });
        result.items.reverse();
        if (result.count > 0) {
          return collection.trigger('add.assets', result.items);
        }
      });
    },
    _diffresult: function(a, b) {
      var i, result;
      result = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = a.length; _i < _len; _i++) {
          i = a[_i];
          if (__indexOf.call(b, i) < 0) {
            _results.push(i);
          }
        }
        return _results;
      })();
      return result.concat((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = b.length; _i < _len; _i++) {
          i = b[_i];
          if (__indexOf.call(a, i) < 0) {
            _results.push(i);
          }
        }
        return _results;
      })());
    },
    _orderdiff: function(listA, listB) {
      return listA.filter(function(item, idx, list) {
        return idx !== listB.indexOf(item);
      });
    },
    _update_proxy: function(message) {
      return this.get({
        ids: message.ids
      }, false);
    },
    _serving_url_change: function(message) {
      var asset;
      asset = this.globalFind(message.id);
      if (asset && asset.count() < message.count) {
        return this.get({
          ids: [message.id]
        });
      } else if (asset && message.s_url && asset.serving_url !== message.s_url) {
        asset.serving_url = message.s_url;
        return asset.save({
          ajax: false
        });
      } else if (!asset) {
        return this.get({
          ids: [message.id]
        }, false);
      }
    },
    _add: function(message) {
      var _this = this;
      if (message.data) {
        return this.parse_data(message.data);
      } else {
        return this.getSearch({
          ids: [message.id]
        }).done(function(data, status, xhr) {
          return _this.parse_data(data);
        });
      }
    },
    _delete: function(message) {
      var asset;
      asset = _this.globalFind(message.id);
      return asset.destroy({
        ajax: false
      });
    },
    _swith_ids: function(message) {
      var CollectionModel, asset, col, cols, p_holder, _i, _j, _len, _len1, _ref, _ref1;
      CollectionModel = this.get_model('Collection');
      asset = this.globalExists(message.from_id);
      if (!asset) {
        return;
      }
      if (this.globalExists(message.to_id)) {
        p_holder = asset;
        asset = this.globalFind(message.to_id);
        cols = CollectionModel.select(function(col) {
          var _ref;
          return _ref = p_holder.id, __indexOf.call(col.assets, _ref) >= 0;
        });
        for (_i = 0, _len = cols.length; _i < _len; _i++) {
          col = cols[_i];
          col.assets.splice(p_holder.id, 1, asset.id);
          if (((_ref = col.serving_url) != null ? _ref.indexOf('http://') : void 0) < 0) {
            col.serving_url = asset.serving_url;
          }
          col.save();
          col.trigger('add.assets', [asset.id]);
          col.trigger('delete.assets', [p_holder.id]);
        }
        p_holder.destroy({
          ajax: false
        });
      } else {
        asset.changeID(message.to_id, {
          ajax: false
        });
        cols = CollectionModel.select(function(col) {
          var _ref1;
          return _ref1 = message.from_id, __indexOf.call(col.assets, _ref1) >= 0;
        });
        for (_j = 0, _len1 = cols.length; _j < _len1; _j++) {
          col = cols[_j];
          if (col && (_ref1 = message.from_id, __indexOf.call(col.assets, _ref1) >= 0)) {
            col.assets.splice(message.from_id, 1, asset.id);
            col.hidden.splice(message.from_id, 1, asset.id);
            col.save({
              ajax: false
            });
          }
        }
      }
      return asset.save({
        ajax: false
      });
    }
  };

  module.exports = Nex.Pusher;

}).call(this);

/*
//@ sourceMappingURL=pusher.map
*/