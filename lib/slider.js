// Generated by CoffeeScript 1.9.3
(function() {
  var Nex, Slide,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  require("./panel");

  Nex = this.Nex || require('nex');

  Nex.Widgets.Slider = (function(superClass) {
    extend(Slider, superClass);

    Slider.include(Nex.Panel);

    Slider.prototype.logPrefix = '(App) Nex.Slider: ';

    Slider.prototype.className = 'nexslider';

    Slider.prototype.defaults = {
      animation: 'fade',
      sizemode: 'fit',
      current: 0,
      enablekeys: true,
      enablearrows: true,
      enablehtml: true,
      subslides: false,
      loop: true,
      responsive: true,
      current: 0,
      lazy: false,
      align: 'center center',
      controls: false
    };

    Slider.prototype.events = {
      'tap .next': 'goNext',
      'tap .prev': 'goPrev'
    };

    function Slider() {
      this.goPrev = bind(this.goPrev, this);
      this.goNext = bind(this.goNext, this);
      this.render = bind(this.render, this);
      this.onKeyup = bind(this.onKeyup, this);
      var key, ref, value;
      ref = this.defaults;
      for (key in ref) {
        value = ref[key];
        this[key] = value;
      }
      Slider.__super__.constructor.apply(this, arguments);
      if (Nex.Utils.isMobile()) {
        this.log('isMobile');
        this.el.on("swipeleft", this.goNext);
        this.el.on("swipeLeft", this.goNext);
        this.el.on("swiperight", this.goPrev);
        this.el.on("swipeRight", this.goPrev);
      }
      this.el.addClass(this.animation);
      this.manager = new Spine.Manager;
      this.slides = this.manager.controllers;
      this.slidesObj = {};
      this.bind('ready', this.render);
      this.id || (this.id = Nex.Utils.uuid());
      this.touch = {};
      if (this.enablekeys) {
        $(document).on("keydown." + this.id, this.onKeyup);
      }
      if (this["class"]) {
        this.el.addClass(this["class"]);
      }
      if (this.data) {
        this.el.data(this.data);
      }
      if (this.enablearrows) {
        this.html('<div class="prev"></div><div class="next"></div>');
      }
      if (this.path) {
        this.getData(this.path);
      } else if (this.collection && this.collection.length > 0) {
        this.render(this.collection);
      } else {
        this.active(this.getData);
      }
      if (this.name) {
        this.el.addClass(this.name);
      }
    }

    Slider.prototype.onKeyup = function(e) {
      if (!(this.enablekeys && this.isActive())) {
        return;
      }
      switch (e.keyCode) {
        case 37:
          return this.goPrev();
        case 39:
          return this.goNext();
      }
    };

    Slider.prototype.render = function(result) {
      var asset, col, i, j, k, len, len1, ref;
      if (!result.length) {
        return;
      }
      if (!this.isActive()) {
        this.activate();
      }
      for (j = 0, len = result.length; j < len; j++) {
        col = result[j];
        if (!(col.items.length > 0)) {
          return;
        }
        ref = col.items;
        for (i = k = 0, len1 = ref.length; k < len1; i = ++k) {
          asset = ref[i];
          this.add(this.slidesObj[asset.normname] = new Slide({
            slider: this,
            asset: asset,
            sizemode: this.sizemode,
            subslides: asset.getMeta('subslides', this.subslides),
            height: this.height,
            width: this.width,
            responsive: this.responsive,
            lazy: this.lazy,
            align: this.align,
            enablehtml: this.enablehtml,
            controls: this.controls
          }));
        }
      }
      this.goto(this.current);
      return this.delay((function(_this) {
        return function() {
          return _this.trigger('rendered', result);
        };
      })(this));
    };

    Slider.prototype.clear = function() {
      var cont, j, len, ref, results;
      ref = this.controllers;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        cont = ref[j];
        results.push(this.controllers[0].release());
      }
      return results;
    };

    Slider.prototype.add = function(controller) {
      this.manager.add(controller);
      return this.append(controller);
    };

    Slider.prototype.goNext = function(e) {
      var ref;
      if ((e != null ? (ref = e.target) != null ? ref.type : void 0 : void 0) === 'range') {
        return;
      }
      this.direction = 'next';
      return this.goto('next');
    };

    Slider.prototype.goPrev = function(e) {
      var ref;
      if ((e != null ? (ref = e.target) != null ? ref.type : void 0 : void 0) === 'range') {
        return;
      }
      this.direction = 'prev';
      return this.goto('prev');
    };

    Slider.prototype.goto = function(slide) {
      var base, next, ref, ref1, ref2;
      if (!this.slides) {
        return this.log('no slides');
      }
      this.trigger('slide', this);
      switch (slide) {
        case 'first':
          next = 0;
          break;
        case 'last':
          next = this.getLast();
          break;
        case 'next':
          next = this.getNext(this.current);
          break;
        case 'prev':
          next = this.getPrev(this.current);
          break;
        default:
          next = Number(slide);
      }
      if (!this.slides.length) {
        return;
      }
      if (this.slides.length === 1) {
        this.enablearrows = false;
        this.enablekeys = false;
        if (typeof (base = this.slides[this.current]).active === "function") {
          base.active();
        }
        this.el.addClass('first last');
        if (slide === 'next') {
          this.trigger('end');
        } else if (slide === 'prev') {
          this.trigger('start');
        }
        return;
      }
      if (!this.loop) {
        if (this.slides.length > 1) {
          if (this.current === this.slides.length - 1 && next === 0 && this.direction === 'next') {
            this.trigger('end');
            return;
          } else if (this.current === 0 && next === this.slides.length - 1 && this.direction === 'prev') {
            this.trigger('start');
            return;
          }
        }
      }
      if ((ref = this.slides[this.prev]) != null) {
        ref.el.removeClass('prevslide');
      }
      if ((ref1 = this.slides[this.next]) != null) {
        ref1.el.removeClass('nextslide');
      }
      this.current = next;
      this.prev = this.getPrev(this.current);
      this.next = this.getNext(this.current);
      this.slides[this.prev].el.addClass('prevslide');
      this.slides[this.next].el.addClass('nextslide');
      if ((ref2 = this.slides[this.current]) != null) {
        ref2.active();
      }
      this.trigger('change', this);
      this.direction = '';
      if (this.current === 0) {
        this.trigger('first');
        this.el.addClass('first');
        this.el.removeClass('last');
      } else if (this.current === this.slides.length - 1) {
        this.trigger('last');
        this.el.addClass('last');
        this.el.removeClass('first');
      } else {
        this.el.removeClass('first last');
      }
      return this.preload();
    };

    Slider.prototype.getPrev = function(i) {
      if (i === 0) {
        return this.slides.length - 1;
      } else {
        return i - 1;
      }
    };

    Slider.prototype.getNext = function(i) {
      if (i === this.slides.length - 1) {
        return 0;
      } else {
        return i + 1;
      }
    };

    Slider.prototype.getLast = function() {
      return this.slides.length - 1;
    };

    Slider.prototype.release = function() {
      var cont, j, len, ref;
      if (this.enablekeys) {
        $(document).off("keydown." + this.id);
      }
      ref = this.slides;
      for (j = 0, len = ref.length; j < len; j++) {
        cont = ref[j];
        this.slides[0].release();
      }
      return Slider.__super__.release.apply(this, arguments);
    };

    Slider.prototype.preload = function() {
      var cont, j, len, ref, results;
      ref = this.slides;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        cont = ref[j];
        if (!cont.isActive()) {
          continue;
        }
        results.push(typeof cont.preload === "function" ? cont.preload() : void 0);
      }
      return results;
    };

    return Slider;

  })(Spine.Controller);

  module.exports = Nex.Widgets.Slider;

  Slide = (function(superClass) {
    extend(Slide, superClass);

    Slide.include(Nex.Panel);

    Slide.prototype.logPrefix = '(App) Slide: ';

    Slide.prototype.className = 'slide';

    Slide.prototype.events = {
      'tap': 'onClick'
    };

    function Slide() {
      Slide.__super__.constructor.apply(this, arguments);
      this.controllers = [];
      if (this.asset.assets && this.subslides) {
        this.bind('ready', this.render);
        this.getData(this.asset.path);
      } else {
        this.render([this.asset]);
      }
    }

    Slide.prototype.onClick = function() {
      return this.slider.trigger('click', this);
    };

    Slide.prototype.render = function(result) {
      var asset, col, html, i, j, k, len, len1, ref, ref1;
      for (j = 0, len = result.length; j < len; j++) {
        col = result[j];
        if (col.kind === 'Collection' && this.subslides) {
          ref = col.items;
          for (i = k = 0, len1 = ref.length; k < len1; i = ++k) {
            asset = ref[i];
            this.add(new Slide({
              slider: this.slider,
              asset: asset,
              sizemode: this.sizemode,
              className: "slidecontent " + (asset.getMeta('crop', '')) + " " + (asset.getMeta('cssclass', '')),
              responsive: this.responsive,
              lazy: this.lazy,
              align: this.align,
              enablehtml: this.enablehtml,
              controls: this.controls
            }));
          }
        } else {
          this.kind = (ref1 = col.kind) === 'Image' || ref1 === 'Video' ? col.kind : 'Image';
          if (!col.serving_url) {
            return this.log('no serving_url for widget in slide');
          }
          this.add(this["media"] = new Nex.Widgets[this.kind]({
            src: col.serving_url,
            align: col.getMeta('crop', 'center center'),
            resolution: col.resolution,
            uuid: col.id,
            formats: col.formats,
            sizemode: col.getMeta('sizemode', [this.sizemode])[0],
            height: this.height,
            width: this.width,
            responsive: this.responsive,
            lazy: this.lazy,
            controls: this.controls
          }));
          if (typeof this.enablehtml === 'boolean' && this.enablehtml) {
            html = col.getMeta('text', col.getMeta('html', ''));
          } else if (typeof this.enablehtml === 'string') {
            html = col.getMeta('text', col.getMeta(this.enablehtml, ''));
          } else if (typeof this.enablehtml === 'function') {
            html = this.enablehtml(col);
          }
          if (html) {
            this.append(html);
          }
        }
        if (this.kind === 'Video') {
          this.listenTo(this.slider, 'change', (function(_this) {
            return function() {
              _this.media.preload();
              return _this.media.pause();
            };
          })(this));
        }
      }
    };

    Slide.prototype.activate = function() {
      var cont, j, len, ref, results;
      Slide.__super__.activate.apply(this, arguments);
      if (this.subslides) {
        ref = this.controllers;
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          cont = ref[j];
          results.push(typeof cont.preload === "function" ? cont.preload() : void 0);
        }
        return results;
      }
    };

    Slide.prototype.deactivate = function() {
      Slide.__super__.deactivate.apply(this, arguments);
      return this.el.removeClass('prev next');
    };

    Slide.prototype.preload = function() {
      var cont, j, len, ref, results;
      ref = this.controllers;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        cont = ref[j];
        results.push(typeof cont.preload === "function" ? cont.preload() : void 0);
      }
      return results;
    };

    Slide.prototype.add = function(controller) {
      this.controllers.push(controller);
      return this.append(controller);
    };

    Slide.prototype.clear = function() {
      var cont, j, len, ref;
      ref = this.controllers;
      for (j = 0, len = ref.length; j < len; j++) {
        cont = ref[j];
        this.controllers[0].release();
      }
      this.controllers = [];
      return this.html('');
    };

    Slide.prototype.release = function() {
      this.clear();
      return Slide.__super__.release.apply(this, arguments);
    };

    return Slide;

  })(Spine.Controller);

}).call(this);
