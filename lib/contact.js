// Generated by CoffeeScript 1.6.3
(function() {
  var isBlank,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  isBlank = Spine.isBlank;

  Nex.Contact = (function(_super) {
    __extends(Contact, _super);

    Contact.prototype.className = 'contact';

    Contact.prototype.events = {
      'tap .send': 'send',
      'keyup': 'onkeyup'
    };

    Contact.prototype.elements = {
      'form': 'form'
    };

    Contact.prototype.defaults = {
      dataType: 'json',
      processData: false,
      headers: {
        'X-Requested-With': 'XMLHttpRequest'
      }
    };

    function Contact() {
      this.send = __bind(this.send, this);
      this.getxsrf = __bind(this.getxsrf, this);
      Contact.__super__.constructor.apply(this, arguments);
      this.logPrefix = '(App) Contact: ';
      this.html(require('views/contact'));
    }

    Contact.prototype.onkeyup = function(e) {
      return this.validate(e.target);
    };

    Contact.prototype.validate = function(el) {
      var field;
      field = $(el).parent();
      if (el.checkValidity()) {
        return field.removeClass('error');
      } else {
        return field.addClass('error');
      }
    };

    Contact.prototype.getxsrf = function(xhr, settings) {
      var _this = this;
      return $.ajax({
        type: 'GET',
        async: false,
        url: Nex.debug ? "http://" + Nex.tenant + ".imagoapp.com/api/v2/getxsrf" : "/api/v2/getxsrf"
      }).success(function(data) {
        return xhr.setRequestHeader("Nex-Xsrf", data);
      }).error(function() {
        return _this.el.addClass('error');
      });
    };

    Contact.prototype.send = function(e) {
      var data, field, settings, _i, _len, _ref,
        _this = this;
      e.preventDefault();
      _ref = $('input,textarea');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        field = _ref[_i];
        this.validate(field);
      }
      if (!this.form[0].checkValidity()) {
        return;
      }
      data = this.form.serialize();
      settings = {
        beforeSend: this.getxsrf,
        data: JSON.stringify(data),
        url: Nex.debug ? "http://" + Nex.tenant + ".imagoapp.com/api/v2/contact" : "/api/v2/contact",
        method: 'POST'
      };
      settings = $.extend({}, this.defaults, settings);
      return $.ajax(settings).success(function(e) {
        return _this.el.addClass('success');
      }).error(function(e) {
        return console.log("error with form", e);
      });
    };

    return Contact;

  })(Spine.Controller);

  module.exports = Nex.Contact;

}).call(this);

/*
//@ sourceMappingURL=contact.map
*/