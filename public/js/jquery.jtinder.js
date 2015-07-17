/*
 * jTinder v.1.0.0
 * https://github.com/do-web/jTinder
 * Requires jQuery 1.7+, jQuery transform2d
 *
 * Copyright (c) 2014, Dominik Weber
 * Licensed under GPL Version 2.
 * https://github.com/do-web/jTinder/blob/master/LICENSE
 */

/*
 * Heavily modified by Zarino Zappia at mySociety
 * to work with dynamically generated list items
 */

;(function ($, window, document, undefined) {
  var pluginName = "jTinder",
    defaults = {
      onDislike: null,
      onLike: null,
      animationRevertSpeed: 200,
      animationSpeed: 400,
      threshold: 1,
      likeSelector: '.like',
      dislikeSelector: '.dislike'
    };

  var container = null;
  var $that = null;
  var xStart = 0;
  var yStart = 0;
  var touchStart = false;
  var posX = 0, posY = 0, lastPosX = 0, lastPosY = 0, pane_width = 0;

  function Plugin(element, options) {
    this.element = element;
    this.settings = $.extend({}, defaults, options);
    this._defaults = defaults;
    this._name = pluginName;
    this.init(element);
  }

  Plugin.prototype = {


    init: function (element) {

      container = $(">ul", element);
      pane_width = container.width();
      $that = this;

      container.bind('touchstart mousedown', this.handler);
      container.bind('touchmove mousemove', this.handler);
      container.bind('touchend mouseup', this.handler);
    },

    getPanes: function(){
      return $(">ul>li", this.element);
    },

    getCurrentPane: function(){
      return $that.getPanes().filter(':first-child');
    },

    skip: function () {
      $that.getCurrentPane().animate({
        "transform": "scale(1.2)",
        "opacity": 0
      }, 200, function(){
        $(this).remove();
      });
    },

    next: function () {
      $that.getCurrentPane().remove();
    },

    dislike: function() {
      var currentPane = $that.getCurrentPane();
      currentPane.find($that.settings.dislikeSelector).css('opacity', 1);
      currentPane.find($that.settings.likeSelector).css('opacity', 0);
      currentPane.animate({
        "transform": "translate(-" + (pane_width) + "px," + (pane_width*-1.5) + "px) rotate(-60deg)"
      }, $that.settings.animationSpeed, function () {
        if($that.settings.onDislike) {
          $that.settings.onDislike($that.getCurrentPane());
        }
        $that.next();
      });
    },

    like: function() {
      var currentPane = $that.getCurrentPane();
      currentPane.find($that.settings.likeSelector).css('opacity', 1);
      currentPane.find($that.settings.dislikeSelector).css('opacity', 0);
      currentPane.animate({
        "transform": "translate(" + (pane_width) + "px," + (pane_width*-1.5) + "px) rotate(60deg)"
      }, $that.settings.animationSpeed, function () {
        if($that.settings.onLike) {
          $that.settings.onLike($that.getCurrentPane());
        }
        $that.next();
      });
    },

    handler: function (ev) {
      ev.preventDefault();
      var panes = $that.getPanes();
      var currentPane = $that.getCurrentPane();

      switch (ev.type) {
        case 'touchstart':
          if(touchStart === false) {
            touchStart = true;
            xStart = ev.originalEvent.touches[0].pageX;
            yStart = ev.originalEvent.touches[0].pageY;
          }
        case 'mousedown':
          if(touchStart === false) {
            touchStart = true;
            xStart = ev.pageX;
            yStart = ev.pageY;
          }
        case 'mousemove':
        case 'touchmove':
          if(touchStart === true) {
            var pageX = typeof ev.pageX == 'undefined' ? ev.originalEvent.touches[0].pageX : ev.pageX;
            var pageY = typeof ev.pageY == 'undefined' ? ev.originalEvent.touches[0].pageY : ev.pageY;
            var deltaX = parseInt(pageX) - parseInt(xStart);
            var deltaY = parseInt(pageY) - parseInt(yStart);
            var percent = ((100 / pane_width) * deltaX) / panes.length;
            posX = deltaX + lastPosX;
            posY = deltaY + lastPosY;

            currentPane.css("transform", "translate(" + posX + "px," + posY + "px) rotate(" + (percent / 2) + "deg)");

            var opa = (Math.abs(deltaX) / $that.settings.threshold) / 100 + 0.2;
            if(opa > 1.0) {
              opa = 1.0;
            }
            if (posX >= 0) {
              currentPane.find($that.settings.likeSelector).css('opacity', opa);
              currentPane.find($that.settings.dislikeSelector).css('opacity', 0);
            } else if (posX < 0) {
              currentPane.find($that.settings.dislikeSelector).css('opacity', opa);
              currentPane.find($that.settings.likeSelector).css('opacity', 0);
            }
          }
          break;
        case 'mouseup':
        case 'touchend':
          touchStart = false;
          var pageX = (typeof ev.pageX == 'undefined') ? ev.originalEvent.changedTouches[0].pageX : ev.pageX;
          var pageY = (typeof ev.pageY == 'undefined') ? ev.originalEvent.changedTouches[0].pageY : ev.pageY;
          var deltaX = parseInt(pageX) - parseInt(xStart);
          var deltaY = parseInt(pageY) - parseInt(yStart);

          posX = deltaX + lastPosX;
          posY = deltaY + lastPosY;
          var opa = Math.abs((Math.abs(deltaX) / $that.settings.threshold) / 100 + 0.2);

          if (opa >= 1) {
            if (posX > 0) {
              currentPane.animate({"transform": "translate(" + (pane_width) + "px," + (posY + pane_width) + "px) rotate(60deg)"}, $that.settings.animationSpeed, function () {
                if($that.settings.onLike) {
                  $that.settings.onLike(currentPane);
                }
                $that.next();
              });
            } else {
              currentPane.animate({"transform": "translate(-" + (pane_width) + "px," + (posY + pane_width) + "px) rotate(-60deg)"}, $that.settings.animationSpeed, function () {
                if($that.settings.onDislike) {
                  $that.settings.onDislike(currentPane);
                }
                $that.next();
              });
            }
          } else {
            lastPosX = 0;
            lastPosY = 0;
            currentPane.animate({"transform": "translate(0px,0px) rotate(0deg)"}, $that.settings.animationRevertSpeed);
            currentPane.find($that.settings.likeSelector).animate({"opacity": 0}, $that.settings.animationRevertSpeed);
            currentPane.find($that.settings.dislikeSelector).animate({"opacity": 0}, $that.settings.animationRevertSpeed);
          }
          break;
      }
    }
  };

  $.fn[ pluginName ] = function (options) {
    this.each(function () {
      if (!$.data(this, "plugin_" + pluginName)) {
        $.data(this, "plugin_" + pluginName, new Plugin(this, options));
      }
      else if ($.isFunction(Plugin.prototype[options])) {
        $.data(this, 'plugin_' + pluginName)[options]();
        }
    });

    return this;
  };

})(jQuery, window, document);