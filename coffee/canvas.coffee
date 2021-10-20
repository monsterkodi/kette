###
 0000000   0000000   000   000  000   000   0000000    0000000    
000       000   000  0000  000  000   000  000   000  000         
000       000000000  000 0 000   000 000   000000000  0000000     
000       000   000  000  0000     000     000   000       000    
 0000000  000   000  000   000      0      000   000  0000000     
###

{ clamp, drag, elem, kpos, post, stash } = require 'kxk'
{ abs } = Math

class Canvas
    
    @: (@parent, @network) ->
        
        @zoom = 
            value:          1.0       # current zoom value
            max:            50        # maximum value of magnification
            min:            0.01      # minimum value of minification
            viewCenter:     kpos 0 0
        
        @div = elem class:"graphDiv" parent:@parent
        
        @div.addEventListener 'contextmenu' @onContextMenu
                       
        @initCanvas()
                
        post.on 'resize'  @onResize
        post.on 'stash'   @onStash
        post.on 'restore' @onRestore
          
    #  0000000   0000000   000   000  000   000   0000000    0000000  
    # 000       000   000  0000  000  000   000  000   000  000       
    # 000       000000000  000 0 000   000 000   000000000  0000000   
    # 000       000   000  000  0000     000     000   000       000  
    #  0000000  000   000  000   000      0      000   000  0000000   
        
    initCanvas: ->
        
        @canvas?.remove()
        
        br = @div.getBoundingClientRect()
        w = parseInt br.width
        h = parseInt br.height
        
        @width  = w*2
        @height = h*2
        
        @canvas = elem 'canvas' class:"canvas graph" width:@width, height:@height, tabindex:1
        @canvas.addEventListener 'wheel'      @onWheel
        @canvas.addEventListener 'mousemove'  @onMouseMove
        @canvas.addEventListener 'mouseleave' @onMouseLeave
        # @canvas.addEventListener 'paste'      @onPaste
        @ctx = @canvas.getContext '2d'
        
        x = parseInt -@width/4
        y = parseInt -@height/4
        @canvas.style.transform = "translate3d(#{x}px, #{y}px, 0px) scale3d(0.5, 0.5, 1)"
        @div.appendChild @canvas

        @drag = new drag
            target:  @canvas
            onMove:  @onDragMove
            onStop:  @onDragStop

    clear: -> @canvas.height = @canvas.height
                
    posForEvent: (event) ->
        
        eventPos = kpos event
        
        br = @div.getBoundingClientRect()
        eventPos.x -= parseInt br.left
        eventPos.y -= parseInt br.top
        
        eventPos
            
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDragMove: (drag, event) => @moveByViewDelta drag.delta
    onDragStop: (drag, event) =>
        
        if drag.startPos.minus(drag.lastPos).length() <= 10
            
            if event.button == 0
                @popup?.close()
                delete @popup
            
    # 00     00   0000000   000   000   0000000  00000000  
    # 000   000  000   000  000   000  000       000       
    # 000000000  000   000  000   000  0000000   0000000   
    # 000 0 000  000   000  000   000       000  000       
    # 000   000   0000000    0000000   0000000   00000000  
    
    onMouseMove: (event) =>

        if @lastMouseEvent = event
            
            @mousePos = @posForEvent event
            @mousePos ?= kpos 0 0

            @mousePos.x -= 2
            @mousePos.y -= 4
    
            if not event.buttons # if button is pressed, 
                @redraw()        # redraw will be done in onDragMove

    onMouseLeave: (event) =>
        
        delete @mousePos
        @redraw()

    # 000   000  000   000  00000000  00000000  000      
    # 000 0 000  000   000  000       000       000      
    # 000000000  000000000  0000000   0000000   000      
    # 000   000  000   000  000       000       000      
    # 00     00  000   000  00000000  00000000  0000000  
    
    onWheel: (event) =>
        
        eventPos = @posForEvent event
        scaleFactor = 1 - event.deltaY / 600.0
        newZoom = clamp @zoom.min, @zoom.max, @zoom.value * scaleFactor
             
        if @zoom.value != newZoom
                 
            @zoomAtViewPos newZoom, eventPos
                         
    # 0000000   0000000    0000000   00     00  
    #    000   000   000  000   000  000   000  
    #   000    000   000  000   000  000000000  
    #  000     000   000  000   000  000 0 000  
    # 0000000   0000000    0000000   000   000  
    
    zoomAtViewPos: (newZoom, viewPos) ->
           
        center = viewPos.times 2
        ref = kpos 0 0
        @zoom.viewCenter.add (ref.plus (center.minus ref).scale newZoom / @zoom.value).sub center
        
        @setZoomScale newZoom
                
    setZoomScale: (newZoom) ->

        @zoom.value = newZoom
        
        x = parseInt -@width/4 - @zoom.viewCenter.x
        y = parseInt -@height/4 - @zoom.viewCenter.y
        @canvas.style.transform = "translate3d(#{x}px, #{y}px, 0px) scale3d(#{@zoom.value/2}, #{@zoom.value/2}, 1)"
        
    moveByViewDelta: (delta) -> 
    
        @zoom.viewCenter.sub delta.times 2
        @setZoomScale @zoom.value
    
    resetZoom: =>
        
        @zoom.value = 1
        @zoom.viewCenter.x = 0
        @zoom.viewCenter.y = @height
        @zoomAtViewPos @zoom.value, kpos 0.5 0.5
        
    # 00000000   00000000   0000000  000  0000000  00000000  
    # 000   000  000       000       000     000   000       
    # 0000000    0000000   0000000   000    000    0000000   
    # 000   000  000            000  000   000     000       
    # 000   000  00000000  0000000   000  0000000  00000000  
    
    onResize: =>
        
        @initCanvas()        
        @redraw()
    
    #  0000000   000   000  000  00     00   0000000   000000000  000   0000000   000   000  
    # 000   000  0000  000  000  000   000  000   000     000     000  000   000  0000  000  
    # 000000000  000 0 000  000  000000000  000000000     000     000  000   000  000 0 000  
    # 000   000  000  0000  000  000 0 000  000   000     000     000  000   000  000  0000  
    # 000   000  000   000  000  000   000  000   000     000     000   0000000   000   000  
    
    redraw: -> @dirty = true
    
    onAnimationFrame: =>

        @clear()
        @draw()
        @dirty = false
            
    # 0000000    00000000    0000000   000   000  
    # 000   000  000   000  000   000  000 0 000  
    # 000   000  0000000    000000000  000000000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000  00     00  
    
    draw: ->
        # klog @width, @height
        @ctx.strokeStyle = '#888'
        @ctx.fillStyle = '#444'
        @ctx.lineWidth = 4
        
        x = @width/2
        y = @height/2
        
        @ctx.beginPath()
        @ctx.moveTo x, y
        for belt in @network.belts
            x += belt.length*50
            @ctx.lineTo x, y
        @ctx.stroke()
        
        x = @width/2
        for belt in @network.belts
            @ctx.fillRect x-5, y-5, 10, 10
            
            item = belt.head
            while item
                @ctx.fillRect x-25 + item.pos*50, y-25, 50, 50
                @ctx.strokeRect x-25 + item.pos*50, y-25, 50, 50
                item = item.prev
                
            x += belt.length*50
                
    #  0000000  000000000   0000000    0000000  000   000  
    # 000          000     000   000  000       000   000  
    # 0000000      000     000000000  0000000   000000000  
    #      000     000     000   000       000  000   000  
    # 0000000      000     000   000  0000000   000   000  
    
    onStash: => stash = window.stash
        
    onRestore: => stash = window.stash
        
    onMenuAction: (action, args) ->
        
        switch action 
            when 'reset zoom' then return @resetZoom()
            
        'unhandled'
        
    # 000   000  00000000  000   000    
    # 000  000   000        000 000     
    # 0000000    0000000     00000      
    # 000  000   000          000       
    # 000   000  00000000     000       
        
    modKeyComboEventDown: (mod, key, combo, event) ->
                        
module.exports = Canvas
