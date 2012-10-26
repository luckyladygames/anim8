###
v: 0.0.4 alpha
###

#
# Copyright (C) 2012 Benson Wong
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
# polyfill for request animation time... 
# credit: http://paulirish.com/2011/requestanimationframe-for-smart-animating/
do ->
    # hey, there's no point if it already exists... 
    return if window.requestAnimationFrame

    lastTime = 0
    vendors = ["ms", "moz", "webkit", "o"]
    for vendor in vendors 
        break if window.requestAnimationFrame?
        window.requestAnimationFrame = window["#{vendor}RequestAnimationFrame"]
        window.cancelAnimationFrame  = window["#{vendor}CancelAnimationFrame"] || window["#{vendor}CancelRequestAnimationFrame"]
  
    # let's do something really crazy! 
    if !window.requestAnimationFrame? 
        window.requestAnimationFrame = (callback, element) ->
            curTime = new Date().getTime()
            timeToCall = Math.max 0, 16 - (curTime - lastTime)
            id = window.setTimeout -> 
                callback curTime + timeToCall
            , timeToCall

            lastTime = curTime + timeToCall
            id

    if !window.cancelAnimationFrame
        window.cancelAnimationFrame = (id) ->
            clearTimeout id

    null

#
# Start Plugin 
#
$ = jQuery
# cache of already loaded images and other resources
Cache =
    # this is a really simple cache of $.Deferred objects so we don't pull them down 
    # more than once
    cache: {}
    loadSheet: (src) ->
        if ! @cache[src]?
            def = $.Deferred()
            @cache[src] = def.promise()
            img = new Image
            img.src = src
            img.onload = =>
                def.resolve img
            img.onerror = =>
                def.reject src
            img.onabort = =>
                def.reject src
        
        @cache[src]

    loadIndex: (src) ->
        if ! @cache[src]
            def = $.Deferred()
            @cache[src] = def.promise()
            $.getJSON(src)
                .done (data) ->
                    def.resolve data
                .fail (reason) ->
                    def.reject reason
        @cache[src]

# Hey, straight from the jQuery guidelines ... ;)
methods =
    init: (options) ->
        @each ->
            $this = $(this)

            # break if we are already initialized
            return if $this.data('anim8')

            settings = $.extend
                time : 1.0
                loop: 'infinite'
                play: true
                offsetX: 0
                offsetY: 0
                index: null
                sheet: null
            , options
            
            settings.index = $this.data('index') if $this.data('index')?
            settings.sheet = $this.data('sheet') if $this.data('sheet')?
            settings.time = parseFloat($this.data('time')) if $this.data('time')?
            settings.offsetX = parseInt($this.data('offset-x')) if $this.data('offset-x')?
            settings.offsetY = parseInt($this.data('offset-y')) if $this.data('offset-y')?
            settings.loop = parseInt($this.data('loop')) if $this.data('loop')?

            return $.error("No animation index") unless settings.index?
            return $.error("No animation sheet") unless settings.sheet?

            data =
                ready: false    # the index/sheet have finished loading
                state: "stop"
                curFrame: 0
                lastTime: 0
                loopsRemaining: settings.loop
                offsetX: settings.offsetX
                offsetY: settings.offsetY
                
                # to be loaded later ... when the sheet and index is loaded
                sheet: null
                index: null
                frameCount: 0
                frameDelay: 0

            $this.data("anim8", data)

            $.when(Cache.loadSheet(settings.sheet), Cache.loadIndex(settings.index))
                .done (sheet, index) ->
                    # controls the state of the animation ..
                    data.sheet = sheet 
                    data.index = index
                    data.frameCount = index.frames.length
                    data.frameDelay = settings.time * 1000 / index.frames.length
                    
                    data.ready = true

                    if settings.play == true
                        data.state = "play"
                    else
                        data.state = "stop"

                    $this.trigger('anim8.ready')
                    
                    # draw the first frame of animation so canvas is not
                    # blank...
                    $this.anim8("draw")
                    
    getData: ->
        $(this).data('anim8')

    start: (loopTimes = 'infinite') ->
        @each ->
            data = $(this).anim8('getData')
            return unless data.ready
            data.state = 'play'
            data.loopsRemaining = loopTimes
            $(this).anim8('draw')

    stop: ->
        @each ->
            data = $(this).anim8('getData')
            return unless data.ready
            data.state = 'stop'
            $(this)

    reset: ->
        @each ->
            $(this).anim8('getData').curFrame = 0
            $(this).anim8('draw')  # draw the new frame (0)

    # draws and beings the animation loop
    # drawing usually only 
    draw: ->
        @each ->
            $this = $(this)
            data = $this.data("anim8")

            canvas = $this.get(0)
            context = canvas.getContext "2d"
            
            # 
            # The animation loop function 
            #
            animate = (now) ->
                if (data.lastTime > 0 and now - data.lastTime < data.frameDelay)
                    window.requestAnimationFrame animate
                    return
                
                # looping control
                if data.loopsRemaining != 'infinite'
                    # stop looping on the last frame 
                    if data.curFrame % data.frameCount == data.frameCount - 1
                        data.loopsRemaining -= 1
                        if data.loopsRemaining == 0
                            data.state = 'stop'
                            return $this


                curFrame = data.curFrame % data.frameCount

                tile = data.index.frames[curFrame]
                sSize = tile.spriteSourceSize
                context.clearRect 0, 0, canvas.width, canvas.height
                context.drawImage data.sheet,
                    tile.frame.x, tile.frame.y      # where to clip from the Image data
                    tile.frame.w, tile.frame.h      # size of the tile
                    data.offsetX + sSize.x,         # positioning inside the context
                    data.offsetY + sSize.y,
                    tile.frame.w, tile.frame.h      # size of the tile to draw
                
                # update for next time through the loop
                data.lastTime = now
                data.curFrame += 1

                # repeat the loop 
                window.requestAnimationFrame animate if data.state == 'play'

            window.requestAnimationFrame animate

$.fn.anim8 = (method, args...) ->
    if methods[method]?
        methods[method].apply this, args
    else if typeof method == 'object' || ! method
        methods.init.apply this, arguments
    else
        $.error "Method #{method} does not exist on jQuery.anim8"

            
