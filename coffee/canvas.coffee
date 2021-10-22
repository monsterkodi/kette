###
 0000000   0000000   000   000  000   000   0000000    0000000    
000       000   000  0000  000  000   000  000   000  000         
000       000000000  000 0 000   000 000   000000000  0000000     
000       000   000  000  0000     000     000   000       000    
 0000000  000   000  000   000      0      000   000  0000000     
###

{ clamp, drag, elem, kpos, post, sh, stash } = require 'kxk'
{ max, round } = Math

class Canvas
    
    @: (@parent, @network) ->
        
        @zoom = 
            value:  1.0       # current zoom value
            max:    50        # maximum value of magnification
            min:    0.2       # minimum value of minification
            center: kpos 0 0
        
        @gridSize = 10
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
                
    # 00000000    0000000    0000000  
    # 000   000  000   000  000       
    # 00000000   000   000  0000000   
    # 000        000   000       000  
    # 000         0000000   0000000   
    
    posForEvent: (event) ->
        
        eventPos = kpos event
        
        br = @div.getBoundingClientRect()
        eventPos.x -= parseInt br.left
        eventPos.y -= parseInt br.top
        
        eventPos
        
    gridPosForEvent: (event) ->
        
        wp = @viewToWorld @posForEvent event
        kpos round(wp.x/@gridSize), round(wp.y/@gridSize)
            
    viewToWorld: (viewPos) ->
            
        worldPos = viewPos.minus kpos @width/4, @height/4
        worldPos.scale 2/@zoom.value
        worldPos.add @zoom.center
        worldPos
        
    # 0000000    00000000    0000000    0000000   
    # 000   000  000   000  000   000  000        
    # 000   000  0000000    000000000  000  0000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000   0000000   
    
    onDragStart: (drag, event) => 
    
        if @dragNode = @network.nodeAtPos @gridPosForEvent event
            @div.style.cursor = 'grabbing'
            
        if not @dragNode
            @div.style.cursor = 'move'
    
    onDragMove: (drag, event) => 
    
        if not @dragNode
            @moveByViewDelta drag.delta
            @div.style.cursor = 'move'
        else
            if dropNode = @network.nodeAtPos @gridPosForEvent event
                if dropNode != @dragNode
                    @div.style.cursor = 'pointer'
                else
                    @div.style.cursor = 'grabbing'
            else
                @div.style.cursor = 'grabbing'
        
    onDragStop: (drag, event) =>
        
        if @dragNode
            gp   = @gridPosForEvent event
            belt = @network.addBelt 1, @dragNode.inp[0].p2, gp
            belt.inp = @dragNode
            @dragNode.addOut belt
            if @dropNode = @network.nodeAtPos gp
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

        if event
            
            @mousePos = @gridPosForEvent event
            @mousePos ?= kpos 0 0
            
            if not @dragNode
                if node = @network.nodeAtPos @gridPosForEvent event
                    @div.style.cursor = 'grab'
                else
                    @div.style.cursor = 'default'
                        
    onMouseLeave: (event) =>
        
        delete @mousePos

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
        
    onResize: => @initCanvas()        
    
    onAnimationFrame: =>

        @clear()
        @draw()
            
    # 0000000    00000000    0000000   000   000  
    # 000   000  000   000  000   000  000 0 000  
    # 000   000  0000000    000000000  000000000  
    # 000   000  000   000  000   000  000   000  
    # 0000000    000   000  000   000  00     00  
    
    draw: ->
        
        @ctx.strokeStyle = '#4448'
        @ctx.lineWidth = max 1 @gridSize*@zoom.value
        
        sz = @gridSize * @zoom.value
        sh = sz/2
        xo = @width/2-@zoom.center.x*@zoom.value
        yo = @height/2-@zoom.center.y*@zoom.value
        
        @ctx.lineCap = "round"
        @ctx.beginPath()
        for belt in @network.belts
            @ctx.moveTo xo+belt.p1.x*sz, yo+belt.p1.y*sz
            @ctx.lineTo xo+belt.p2.x*sz, yo+belt.p2.y*sz
        @ctx.stroke()
        
        if @mousePos
            if @dragNode
                @ctx.beginPath()
                @ctx.moveTo xo+@dragNode.pos.x*sz, yo+@dragNode.pos.y*sz
                @ctx.lineTo xo+@mousePos.x*sz, yo+@mousePos.y*sz
                @ctx.stroke()
        
        @ctx.fillStyle = '#888'
        for node in @network.nodes
            @ctx.beginPath()
            @ctx.arc xo+node.pos.x*sz, yo+node.pos.y*sz, sz/4, 0, 2 * Math.PI, false
            @ctx.fill()     
            
        for belt in @network.belts
            
            item = belt.head
            p1top2 = belt.p1.to belt.p2
            
            while item
                @ctx.fillStyle = item.color
                p = belt.p1.plus p1top2.times item.pos/belt.length
                x = xo+p.x*sz
                y = yo+p.y*sz
                if @zoom.value < 1
                    @ctx.fillRect x-sh, y-sh, sz, sz
                else
                    if item.shape == 'circle'
                        @ctx.beginPath()
                        @ctx.arc    x, y, sh, 0, 2 * Math.PI, false
                        @ctx.fill()     
                    else if item.shape == 'triangle'
                        @ctx.beginPath()
                        @ctx.moveTo x-sh, y+sh
                        @ctx.lineTo x+sh, y+sh
                        @ctx.lineTo x,    y-sh
                        @ctx.lineTo x-sh, y+sh
                        @ctx.fill()     
                    else if item.shape == 'diamond'
                        @ctx.beginPath()
                        @ctx.moveTo x,    y+sh
                        @ctx.lineTo x+sh, y
                        @ctx.lineTo x,    y-sh
                        @ctx.lineTo x-sh, y
                        @ctx.lineTo x,    y+sh
                        @ctx.fill()     
                    else
                        @ctx.fillRect x-sh, y-sh, sz, sz
                
                item = item.prev
                
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
