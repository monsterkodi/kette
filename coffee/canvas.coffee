###
 0000000   0000000   000   000  000   000   0000000    0000000    
000       000   000  0000  000  000   000  000   000  000         
000       000000000  000 0 000   000 000   000000000  0000000     
000       000   000  000  0000     000     000   000       000    
 0000000  000   000  000   000      0      000   000  0000000     
###

{ clamp, drag, elem, klog, kpos, post, stash } = require 'kxk'
{ abs } = Math

class Canvas
    
    @: (@parent, @network) ->
        
        @zoom = 
            value:  1.0       # current zoom value
            max:    50        # maximum value of magnification
            min:    0.01      # minimum value of minification
            center: kpos 0 0
        
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
    
    onMouseLeave: (event) =>
        
        delete @mousePos

    # 000   000  000   000  00000000  00000000  000      
    # 000 0 000  000   000  000       000       000      
    # 000000000  000000000  0000000   0000000   000      
    # 000   000  000   000  000       000       000      
    # 00     00  000   000  00000000  00000000  0000000  
    
    onWheel: (event) =>
        
        viewPos = @posForEvent event
        scaleFactor = 1 - event.deltaY / 600.0
        newZoom = clamp @zoom.min, @zoom.max, @zoom.value * scaleFactor
             
        if @zoom.value != newZoom
                 
            worldPos = viewPos.minus kpos @width/4, @height/4
            worldPos.scale 2/@zoom.value
            worldPos.add @zoom.center
            
            @zoom.value = newZoom

            newPos = viewPos.minus kpos @width/4, @height/4
            newPos.scale 2/@zoom.value
            newPos.add @zoom.center
            
            @zoom.center.sub newPos.minus worldPos
            
            # klog worldPos
                         
    # 0000000   0000000    0000000   00     00  
    #    000   000   000  000   000  000   000  
    #   000    000   000  000   000  000000000  
    #  000     000   000  000   000  000 0 000  
    # 0000000   0000000    0000000   000   000  
    
    moveByViewDelta: (delta) -> 
    
        @zoom.center.sub delta.times 2/@zoom.value
        
        klog 'zoom.center' @zoom.center
    
    resetZoom: =>
        
        @zoom.value = 1
        @zoom.center.x = 0
        @zoom.center.y = 0
        
    # 00000000   00000000   0000000  000  0000000  00000000  
    # 000   000  000       000       000     000   000       
    # 0000000    0000000   0000000   000    000    0000000   
    # 000   000  000            000  000   000     000       
    # 000   000  00000000  0000000   000  0000000  00000000  
    
    onResize: => @initCanvas()        
    
    #  0000000   000   000  000  00     00   0000000   000000000  000   0000000   000   000  
    # 000   000  0000  000  000  000   000  000   000     000     000  000   000  0000  000  
    # 000000000  000 0 000  000  000000000  000000000     000     000  000   000  000 0 000  
    # 000   000  000  0000  000  000 0 000  000   000     000     000  000   000  000  0000  
    # 000   000  000   000  000  000   000  000   000     000     000   0000000   000   000  
    
    onAnimationFrame: =>

        @clear()
        @draw()
            
    # 0000000    00000000    0000000   000   000  
    # 000   000  000   000  000   000  000 0 000  
    # 000   000  0000000    000000000  000000000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000  00     00  
    
    draw: ->
        
        @ctx.strokeStyle = '#8888'
        @ctx.lineWidth = 0
        
        sz = 100 * @zoom.value
        xo = @width/2-@zoom.center.x*@zoom.value
        yo = @height/2-@zoom.center.y*@zoom.value
        
        @ctx.beginPath()
        for belt in @network.belts
            @ctx.moveTo xo+belt.p1.x*sz, yo+belt.p1.y*sz
            @ctx.lineTo xo+belt.p2.x*sz, yo+belt.p2.y*sz
        @ctx.stroke()
        
        @ctx.fillStyle = '#8888'
        for belt in @network.belts
            @ctx.fillRect xo+belt.p1.x*sz-sz/4, yo+belt.p1.y*sz-sz/4, sz/2, sz/2
            
        for belt in @network.belts
            item = belt.head
            while item
                @ctx.fillStyle = item.color
                p = belt.p1.plus belt.p1.to(belt.p2).times(item.pos/belt.length)
                
                @ctx.fillRect xo+p.x*sz-sz/2, yo+p.y*sz-sz/2, sz, sz
                item = item.prev
                
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
