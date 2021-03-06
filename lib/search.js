// Generated by CoffeeScript 1.9.3
(function() {
  var Nex,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Nex = this.Nex || require('nex');

  Nex.Search = {
    get: function(params, abortable, fetchAssets, ajax, lean) {
      var deferred, getAssetsDone, getAssetsFail, getCollectionDone, getCollectionFail, getLocalSearchDone, getLocalSearchFail, getSearchDone, getSearchFail, promise, ref, result;
      this.abortable = abortable;
      if (fetchAssets == null) {
        fetchAssets = true;
      }
      if (ajax == null) {
        ajax = true;
      }
      if (lean == null) {
        lean = false;
      }
      if (this.abortable === void 0 && Nex.client === 'public') {
        this.abortable = true;
      }
      if ((ref = this.jqXHR) != null) {
        ref.abort('abort');
      }
      params = this.objListToDict(params);
      if (lean === true) {
        params.lean = lean;
      }
      deferred = $.Deferred();
      promise = deferred.promise();
      result = {
        items: [],
        count: 0
      };
      getAssetsDone = (function(_this) {
        return function(assets, options) {
          if (options == null) {
            options = {};
          }
          if (result.kind === 'Collection') {
            result.items = params.sortoptions ? assets : _this.sortassets(result.assets, assets);
            result.count = assets.length;
            if (options.page) {
              result.next = result.items.length === options.pagesize ? options.page + 1 : void 0;
              result.prev = options.page > 1 ? options.page - 1 : void 0;
            }
          }
          return deferred.resolve(result);
        };
      })(this);
      getAssetsFail = function() {
        return deferred.reject();
      };
      getCollectionDone = (function(_this) {
        return function(collection) {
          if (!collection) {
            return deferred.resolve(result);
          }
          result = collection;
          if (!fetchAssets) {
            return deferred.resolve(result);
          }
          return _this.getAssets(collection, params).done(getAssetsDone).fail(getAssetsFail);
        };
      })(this);
      getCollectionFail = function() {
        return deferred.reject();
      };
      getSearchDone = (function(_this) {
        return function(data, status, xhr) {
          var assets;
          assets = _this.parseData(data);
          result.items = assets.concat(_this.existing || []);
          result.count = assets.length;
          return deferred.resolve(result);
        };
      })(this);
      getSearchFail = function(xhr, statusText, error) {
        return deferred.reject(arguments);
      };
      getLocalSearchDone = (function(_this) {
        return function(data) {
          result.items = data;
          result.count = data.length;
          return deferred.resolve(result);
        };
      })(this);
      getLocalSearchFail = function() {
        return deferred.reject();
      };
      if (ajax === false) {
        this.localSearch(params).done(getLocalSearchDone).fail(getLocalSearchFail);
      } else if (params.path) {
        this.getCollection(params).done(getCollectionDone).fail(getCollectionFail);
      } else {
        this.getSearch(params).done(getSearchDone).fail(getSearchFail);
      }
      return promise;
    },
    localSearch: function(params) {
      var Collection, asset, assets, collection, deferred, id, items, key, kind, path, promise;
      deferred = $.Deferred();
      promise = deferred.promise();
      kind = params.kind;
      if (params.kind) {
        delete params.kind;
      }
      if (params.hasOwnProperty('path')) {
        path = params.path[0];
        if (path !== '/') {
          path = path.replace(/\/$/, "");
        }
        delete params.path;
        Collection = this.get_model('Collection');
        collection = Collection.findByAttribute('path', path);
        assets = (function() {
          var j, len, ref, results;
          ref = collection.assets;
          results = [];
          for (j = 0, len = ref.length; j < len; j++) {
            id = ref[j];
            if (this.globalExists(id)) {
              results.push(this.globalFind(id));
            }
          }
          return results;
        }).call(this);
        if (kind) {
          assets = (function() {
            var j, len, ref, results;
            results = [];
            for (j = 0, len = assets.length; j < len; j++) {
              asset = assets[j];
              if (ref = asset.kind, indexOf.call(kind, ref) >= 0) {
                results.push(asset);
              }
            }
            return results;
          })();
        }
        for (key in params) {
          if (key === 'text') {
            continue;
          }
          assets = assets.filter(function(item) {
            return item.query(params[key], key);
          });
        }
        items = params.text ? assets.filter(function(item) {
          return item.query(params.text);
        }) : assets;
        deferred.resolve(items);
      }
      return promise;
    },
    containedInExcludes: function(params) {
      var colModel, obj, objid;
      if (!params.hasOwnProperty('contained_in')) {
        return params;
      }
      objid = params.contained_in[0];
      colModel = this.get_model('Collection');
      this.existing = colModel.select(function(item) {
        return indexOf.call(item.assets, objid) >= 0;
      });
      params.excludes = (function() {
        var j, len, ref, results;
        ref = this.existing;
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          obj = ref[j];
          results.push(obj.id);
        }
        return results;
      }).call(this);
      return params;
    },
    getSearch: function(params) {
      var jqXHR;
      jqXHR = $.ajax({
        contentType: 'application/json',
        dataType: 'json',
        processData: false,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'NexClient': Nex.client
        },
        type: 'POST',
        data: JSON.stringify(this.containedInExcludes(params)),
        url: this.getSearchUrl()
      });
      jqXHR.always((function(_this) {
        return function() {
          return _this.jqXHR = null;
        };
      })(this));
      jqXHR.fail((function(_this) {
        return function(jqXHR, textStatus, error) {};
      })(this));
      if (this.abortable) {
        this.jqXHR = jqXHR;
      }
      return jqXHR;
    },
    getCollection: function(params) {
      var Collection, collection, deferred, exlude, other, path, promise, query, selector;
      deferred = $.Deferred();
      promise = deferred.promise();
      path = params.path[0];
      if (path !== '/') {
        path = path != null ? path.replace(/\/$/, "") : void 0;
      }
      Collection = this.get_model('Collection');
      collection = Collection.findByAttribute('path', path);
      if (!collection) {
        selector = function(item) {
          return item.path === path;
        };
        other = this.filter(selector, exlude = ['Collection', 'Proxy']);
        if (other.length) {
          collection = other[0];
        }
      }
      if (collection) {
        return deferred.resolve(collection);
      } else {
        query = {
          'path': params.path
        };
        if (params.recursive) {
          query.recursive = true;
        }
        if (params.lean) {
          query.lean = true;
        }
        this.getSearch(query).done((function(_this) {
          return function(data, status, xhr) {
            delete params.path;
            collection = _this.parseData(data)[0];
            return deferred.resolve(collection);
          };
        })(this));
      }
      return promise;
    },
    getAssets: function(collection, params) {
      var assets, deferred, id, ids, lean, offset, page, pagesize, promise, ref, toFetch;
      deferred = $.Deferred();
      promise = deferred.promise();
      delete params.path;
      delete params.recursive;
      if (params.lean === true) {
        lean = params.lean;
      }
      delete params.lean;
      if (collection.kind === 'Collection' && !params.sortoptions) {
        toFetch = collection.assets;
        assets = [];
        page = params.page ? parseInt(params.page) : void 0;
        pagesize = ((ref = collection.meta.pagesize) != null ? ref.value : void 0) || 5000;
        if (!Object.keys(params).length) {
          ids = collection.assets;
        }
        if (Object.keys(params).length === 1 && params.hasOwnProperty('kind')) {
          ids = (function() {
            var j, len, ref1, ref2, results;
            ref1 = collection.assets;
            results = [];
            for (j = 0, len = ref1.length; j < len; j++) {
              id = ref1[j];
              if (ref2 = this.id_to_kind(id), indexOf.call(params.kind, ref2) >= 0) {
                results.push(id);
              }
            }
            return results;
          }).call(this);
        }
        if (Object.keys(params).length === 1 && params.hasOwnProperty('page')) {
          offset = (page - 1) * (params.pagesize = pagesize);
          ids = collection.assets.slice(offset, pagesize * page);
        }
        if (ids != null ? ids.length : void 0) {
          params.ids = toFetch = (function() {
            var j, len, results;
            results = [];
            for (j = 0, len = ids.length; j < len; j++) {
              id = ids[j];
              if (!this.globalExists(id)) {
                results.push(id);
              }
            }
            return results;
          }).call(this);
          assets = (function() {
            var j, len, results;
            results = [];
            for (j = 0, len = ids.length; j < len; j++) {
              id = ids[j];
              if (this.globalExists(id)) {
                results.push(this.globalFind(id));
              }
            }
            return results;
          }).call(this);
        }
        if (!toFetch.length) {
          return deferred.resolve(assets, {
            page: page,
            pagesize: pagesize
          });
        }
        params.ancestor = collection.id;
        if (lean === true) {
          params.lean = lean;
        }
        this.getSearch(params).done((function(_this) {
          return function(data, status, xhr) {
            assets = assets.concat(_this.parseData(data));
            return deferred.resolve(assets, {
              page: page,
              pagesize: pagesize
            });
          };
        })(this));
      } else if (collection.kind === 'Collection' && params.sortoptions) {
        params.ancestor = collection.id;
        this.getSearch(params).done((function(_this) {
          return function(data, status, xhr) {
            return deferred.resolve(_this.parseData(data));
          };
        })(this));
      } else {
        deferred.resolve([]);
      }
      return promise;
    },
    sortassets: function(ids, assets) {
      var asset, i, id, j, k, len, len1, orderedlist;
      orderedlist = [];
      for (j = 0, len = ids.length; j < len; j++) {
        id = ids[j];
        for (i = k = 0, len1 = assets.length; k < len1; i = ++k) {
          asset = assets[i];
          if (asset.id === id) {
            orderedlist.push(asset);
            break;
          }
        }
      }
      return orderedlist;
    },
    parseData: function(data) {
      var asset, j, len, obj, objs;
      objs = [];
      if (typeof data === 'string') {
        data = JSON.parse(data);
      }
      for (j = 0, len = data.length; j < len; j++) {
        obj = data[j];
        asset = this.create_or_update(obj, {
          ajax: false,
          skipAc: true
        });
        objs.push(asset);
      }
      return objs;
    },
    objListToDict: function(obj_or_list) {
      var elem, j, k, key, len, len1, querydict, ref, value;
      querydict = {};
      if (Spine.isArray(obj_or_list)) {
        for (j = 0, len = obj_or_list.length; j < len; j++) {
          elem = obj_or_list[j];
          for (key in elem) {
            value = elem[key];
            querydict[key] || (querydict[key] = []);
            querydict[key].push(value);
          }
        }
      } else {
        for (key in obj_or_list) {
          value = obj_or_list[key];
          querydict[key] = Spine.isArray(value) ? value : [value];
        }
      }
      if (querydict.collection != null) {
        querydict['path'] = querydict.collection;
        delete querydict.collection;
      }
      ref = ['page', 'pagesize'];
      for (k = 0, len1 = ref.length; k < len1; k++) {
        key = ref[k];
        if (querydict.hasOwnProperty(key)) {
          querydict[key] = querydict[key][0];
        }
      }
      return querydict;
    },
    getSearchUrl: function() {
      if (Nex.data === 'online' && Nex.debug) {
        return "http://" + Nex.tenant + ".imagoapp.com/api/v2/search";
      } else {
        return "/api/v2/search";
      }
    }
  };

  module.exports = Nex.Search;

}).call(this);
