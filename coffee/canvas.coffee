###
 0000000   0000000   000   000  000   000   0000000    0000000    
000       000   000  0000  000  000   000  000   000  000         
000       000000000  000 0 000   000 000   000000000  0000000     
000       000   000  000  0000     000     000   000       000    
 0000000  000   000  000   000      0      000   000  0000000     
###

{ clamp, drag, elem, kpos, post, stash } = require 'kxk'
{ max } = Math

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
            onStart: @onDragStart
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
    
    onDragStart: (drag, event) => 
    
        worldPos = @viewToWorld @posForEvent event
        if @dragNode = @network.nodeAtPos worldPos
            @div.style.cursor = 'grabbing'
            
        if not @dragNode
            @div.style.cursor = 'move'
    
    onDragMove: (drag, event) => 
    
        if not @dragNode
            @moveByViewDelta drag.delta
            @div.style.cursor = 'move'
        else
            mp = @viewToWorld @posForEvent event
            if dropNode = @network.nodeAtPos mp
                if dropNode != @dragNode
                    @div.style.cursor = 'pointer'
                else
                    @div.style.cursor = 'grabbing'
            else
                @div.style.cursor = 'grabbing'
        
    onDragStop: (drag, event) =>
        
        if @dragNode
            mp   = @viewToWorld @posForEvent event
            outp = kpos parseInt(mp.x/100+0.499), parseInt(mp.y/100+0.499)
            belt = @network.addBelt 1, @dragNode.inp[0].p2, outp
            belt.inp = @dragNode
            @dragNode.addOut belt
            if @dropNode = @network.nodeAtPos mp
                belt.out = @dropNode
                @dropNode.addInp belt
            else
                @network.addNode belt

        delete @dragNode
        
        @onMouseMove event
        
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
            
            if not @dragNode
                worldPos = @viewToWorld @mousePos
                if node = @network.nodeAtPos worldPos
                    @div.style.cursor = 'grab'
                else
                    @div.style.cursor = 'default'
                
    viewToWorld: (viewPos) ->
            
        worldPos = viewPos.minus kpos @width/4, @height/4
        worldPos.scale 2/@zoom.value
        worldPos.add @zoom.center
        worldPos
        
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
            
    # 0000000   0000000    0000000   00     00  
    #    000   000   000  000   000  000   000  
    #   000    000   000  000   000  000000000  
    #  000     000   000  000   000  000 0 000  
    # 0000000   0000000    0000000   000   000  
    
    moveByViewDelta: (delta) -> 
    
        @zoom.center.sub delta.times 2/@zoom.value
        
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
        @ctx.lineWidth = max 1 10*@zoom.value
        
        sz = 100 * @zoom.value
        xo = @width/2-@zoom.center.x*@zoom.value
        yo = @height/2-@zoom.center.y*@zoom.value
        
        @ctx.beginPath()
        for belt in @network.belts
            @ctx.moveTo xo+belt.p1.x*sz, yo+belt.p1.y*sz
            @ctx.lineTo xo+belt.p2.x*sz, yo+belt.p2.y*sz
        @ctx.stroke()
        
        if @mousePos
            mp = @viewToWorld @mousePos
            if @dragNode
                @ctx.beginPath()
                @ctx.moveTo xo+@dragNode.inp[0].p2.x*sz, yo+@dragNode.inp[0].p2.y*sz
                @ctx.lineTo xo+mp.x*sz/100, yo+mp.y*sz/100
                @ctx.stroke()
        
        @ctx.fillStyle = '#888'
        for node in @network.nodes
            @ctx.beginPath()
            @ctx.arc(xo+node.inp[0].p2.x*sz, yo+node.inp[0].p2.y*sz, sz/4, 0, 2 * Math.PI, false)
            @ctx.fill()     
            
        for belt in @network.belts
            item = belt.head
            while item
                @ctx.fillStyle = item.color
                p = belt.p1.plus belt.p1.to(belt.p2).times(item.pos/belt.length)
                
                if item.shape == 'circle'
                    @ctx.beginPath()
                    @ctx.arc(xo+p.x*sz, yo+p.y*sz, sz/2, 0, 2 * Math.PI, false)
                    @ctx.fill()     
                else if item.shape == 'triangle'
                    @ctx.beginPath()
                    @ctx.moveTo xo+p.x*sz-sz/2, yo+p.y*sz+sz/2
                    @ctx.lineTo xo+p.x*sz+sz/2, yo+p.y*sz+sz/2
                    @ctx.lineTo xo+p.x*sz, yo+p.y*sz-sz/2
                    @ctx.lineTo xo+p.x*sz-sz/2, yo+p.y*sz+sz/2
                    @ctx.fill()     
                else if item.shape == 'diamond'
                    @ctx.beginPath()
                    @ctx.moveTo xo+p.x*sz, yo+p.y*sz+sz/2
                    @ctx.lineTo xo+p.x*sz+sz/2, yo+p.y*sz
                    @ctx.lineTo xo+p.x*sz, yo+p.y*sz-sz/2
                    @ctx.lineTo xo+p.x*sz-sz/2, yo+p.y*sz
                    @ctx.lineTo xo+p.x*sz, yo+p.y*sz+sz/2
                    @ctx.fill()     
                else
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
