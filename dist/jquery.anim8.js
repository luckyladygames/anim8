// Generated by CoffeeScript 1.3.3
(function() {
  var $, Cache, methods,
    __slice = [].slice;

  (function() {
    var lastTime, vendor, vendors, _i, _len;
    if (window.requestAnimationFrame) {
      return;
    }
    lastTime = 0;
    vendors = ["ms", "moz", "webkit", "o"];
    for (_i = 0, _len = vendors.length; _i < _len; _i++) {
      vendor = vendors[_i];
      if (window.requestAnimationFrame != null) {
        break;
      }
      window.requestAnimationFrame = window["" + vendor + "RequestAnimationFrame"];
      window.cancelAnimationFrame = window["" + vendor + "CancelAnimationFrame"] || window["" + vendor + "CancelRequestAnimationFrame"];
    }
    if (!(window.requestAnimationFrame != null)) {
      window.requestAnimationFrame = function(callback, element) {
        var curTime, id, timeToCall;
        curTime = new Date().getTime();
        timeToCall = Math.max(0, 16 - (curTime - lastTime));
        id = window.setTimeout(function() {
          return callback(curTime + timeToCall);
        }, timeToCall);
        lastTime = curTime + timeToCall;
        return id;
      };
    }
    if (!window.cancelAnimationFrame) {
      window.cancelAnimationFrame = function(id) {
        return clearTimeout(id);
      };
    }
    return null;
  })();

  $ = jQuery;

  Cache = {
    cache: {},
    loadSprites: function(src) {
      var def, img,
        _this = this;
      if (!(this.cache[src] != null)) {
        def = $.Deferred();
        this.cache[src] = def.promise();
        img = new Image;
        img.src = src;
        img.onload = function() {
          return def.resolve(img);
        };
        img.onerror = function() {
          return def.reject(src);
        };
        img.onabort = function() {
          return def.reject(src);
        };
      }
      return this.cache[src];
    },
    loadIndex: function(src) {
      var def;
      if (!this.cache[src]) {
        def = $.Deferred();
        this.cache[src] = def.promise();
        $.getJSON(src).done(function(data) {
          return def.resolve(data);
        }).fail(function(reason) {
          return def.reject(reason);
        });
      }
      return this.cache[src];
    }
  };

  methods = {
    init: function(options) {
      var settings;
      settings = $.extend({
        time: 1.0,
        loop: 'infinite',
        play: true,
        offsetX: 0,
        offsetY: 0,
        sprites: null,
        index: null
      }, options);
      return this.each(function() {
        var $this, index, offsetX, offsetY, sprites, time;
        $this = $(this);
        if ($(this).data('anim8')) {
          return;
        }
        index = $this.data('index');
        sprites = $this.data('sprites');
        time = parseFloat($this.data('time'));
        offsetX = parseInt($this.data('offset-x'));
        offsetY = parseInt($this.data('offset-y'));
        return $.when(Cache.loadSprites(sprites), Cache.loadIndex(index)).done(function(sprites, index) {
          var data;
          data = {
            state: "none",
            curFrame: 0,
            lastTime: 0,
            frameCount: index.frames.length,
            frameDelay: time * 1000 / index.frames.length,
            loopsRemaining: settings.loop,
            sprites: sprites,
            index: index,
            offsetX: offsetX,
            offsetY: offsetY
          };
          $this.data("anim8", data);
          if (settings.play === true) {
            data.state = "play";
          }
          return $this.anim8("draw");
        });
      });
    },
    getData: function() {
      return $(this).data('anim8');
    },
    start: function(loopTimes) {
      if (loopTimes == null) {
        loopTimes = 'infinite';
      }
      return this.each(function() {
        var data;
        data = $(this).anim8('getData');
        data.state = 'play';
        data.loopsRemaining = loopTimes;
        return $(this).anim8('draw');
      });
    },
    stop: function() {
      return this.each(function() {
        $(this).anim8('getData').state = 'stop';
        return $(this);
      });
    },
    reset: function() {
      return this.each(function() {
        $(this).anim8('getData').curFrame = 0;
        return $(this).anim8('draw', true);
      });
    },
    draw: function() {
      return this.each(function() {
        var $this, animate, canvas, context, data;
        $this = $(this);
        data = $this.data("anim8");
        canvas = $this.get(0);
        context = canvas.getContext("2d");
        animate = function(now) {
          var curFrame, sSize, tile;
          if (data.lastTime > 0 && now - data.lastTime < data.frameDelay) {
            window.requestAnimationFrame(animate);
            return;
          }
          if (data.loopsRemaining !== 'infinite') {
            if (data.curFrame % data.frameCount === data.frameCount - 1) {
              data.loopsRemaining -= 1;
              if (data.loopsRemaining === 0) {
                data.state = 'stop';
                return $this;
              }
            }
          }
          curFrame = data.curFrame % data.frameCount;
          tile = data.index.frames[curFrame];
          sSize = tile.spriteSourceSize;
          context.clearRect(0, 0, canvas.width, canvas.height);
          context.drawImage(data.sprites, tile.frame.x, tile.frame.y, tile.frame.w, tile.frame.h, data.offsetX + sSize.x, data.offsetY + sSize.y, tile.frame.w, tile.frame.h);
          data.lastTime = now;
          data.curFrame += 1;
          if (data.state === 'play') {
            return window.requestAnimationFrame(animate);
          }
        };
        return window.requestAnimationFrame(animate);
      });
    }
  };

  $.fn.anim8 = function() {
    var args, method;
    method = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if (methods[method] != null) {
      return methods[method].apply(this, args);
    } else if (typeof method === 'object' || !method) {
      return methods.init.apply(this, arguments);
    } else {
      return $.error("Method " + method + " does not exist on jQuery.anim8");
    }
  };

}).call(this);