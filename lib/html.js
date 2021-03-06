// Generated by CoffeeScript 1.9.3
(function() {
  var Nex,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Nex = this.Nex || require('nex');

  Nex.Widgets.Html = (function(superClass) {
    extend(Html, superClass);

    Html.include(Nex.Panel);

    Html.prototype.logPrefix = '(App) Nex.Html: ';

    function Html() {
      var headline, html;
      Html.__super__.constructor.apply(this, arguments);
      headline = this.asset.getMeta('headline');
      if (headline) {
        this.append("<h1>" + headline + "<H1>");
      }
      html = this.asset.getMeta('html');
      if (html) {
        this.append(html);
      }
    }

    return Html;

  })(Spine.Controller);

  module.exports = Nex.Widgets.Html;

}).call(this);
