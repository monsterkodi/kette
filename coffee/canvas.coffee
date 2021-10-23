###
 0000000   0000000   000   000  000   000   0000000    0000000    
000       000   000  0000  000  000   000  000   000  000         
000       000000000  000 0 000   000 000   000000000  0000000     
000       000   000  000  0000     000     000   000       000    
 0000000  000   000  000   000      0      000   000  0000000     
###

{ clamp, drag, elem, kpos, post, sh, stopEvent } = require 'kxk'
{ max, round } = Math

Menu = require './menu'

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
          
    onContextMenu: (event) -> stopEvent event 
        
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
    
        if event.getModifierState "Meta"
            new Menu @posForEvent event
            return
        
        if @dragNode = @network.nodeAtPos @gridPosForEvent event
            @div.style.cursor = 'grabbing'
            
            if not @dragNode.out?
                delete @dragNode
            
        if not @dragNode
            @div.style.cursor = 'move'
    
    onDragMove: (drag, event) => 
    
        if event.getModifierState "Meta"
            return
            
        if not @dragNode
            @moveByViewDelta drag.delta
            @div.style.cursor = 'move'
        else
            if dropNode = @network.nodeAtPos @gridPosForEvent event
                if dropNode != @dragNode and dropNode.inp?
                    @div.style.cursor = 'grab'
                else
                    @div.style.cursor = 'grabbing'
            else
                @div.style.cursor = 'pointer'
        
    onDragStop: (drag, event) =>
        
        if @dragNode
            gp       = @gridPosForEvent event
            dropNode = @network.nodeAtPos gp
            
            if dropNode and not dropNode.inp
                true
            else
                out  = dropNode ? @network.newNode gp
                belt = @network.newBelt @dragNode, out

        delete @dragNode
        
        @onMouseMove event
                    
    # 00     00   0000000   000   000   0000000  00000000  
    # 000   000  000   000  000   000  000       000       
    # 000000000  000   000  000   000  0000000   0000000   
    # 000 0 000  000   000  000   000       000  000       
    # 000   000   0000000    0000000   0000000   00000000  
    
    onMouseMove: (event) =>

        if event
            
            @mousePos = @gridPosForEvent event
            
            if not @dragNode
                if node = @network.nodeAtPos @gridPosForEvent event
                    if node.out?
                        @div.style.cursor = 'grab'
                    else
                        @div.style.cursor = 'default'
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
        
        laneColor = '#222'
        @ctx.strokeStyle = laneColor
        @ctx.lineWidth = max 1 @gridSize*@zoom.value
        
        sz = @gridSize * @zoom.value
        sh = sz/2
        xo = @width/2-@zoom.center.x*@zoom.value
        yo = @height/2-@zoom.center.y*@zoom.value
        
        @ctx.lineCap = "round"
        @ctx.beginPath()
        for belt in @network.belts
            @ctx.moveTo xo+belt.inp.pos.x*sz, yo+belt.inp.pos.y*sz
            @ctx.lineTo xo+belt.out.pos.x*sz, yo+belt.out.pos.y*sz
        @ctx.stroke()
        
        if @mousePos
            if @dragNode
                @ctx.beginPath()
                @ctx.moveTo xo+@dragNode.pos.x*sz, yo+@dragNode.pos.y*sz
                @ctx.lineTo xo+@mousePos.x*sz, yo+@mousePos.y*sz
                @ctx.stroke()
                    
        @ctx.fillStyle = laneColor
        for node in @network.nodes
            @ctx.beginPath()
            @ctx.arc xo+node.pos.x*sz, yo+node.pos.y*sz, sz, 0, 2 * Math.PI, false
            @ctx.fill()     
                
        for belt in @network.belts
            
            item  = belt.head
            inOut = belt.inp.pos.to belt.out.pos
            
            while item
                @ctx.fillStyle = item.color
                p = belt.inp.pos.plus inOut.times item.pos/belt.length
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
                            
        for building in @network.buildings
            x = xo+building.pos.x*sz
            y = yo+building.pos.y*sz
            @ctx.fillStyle = building.color
            
            switch building.type
                when 'miner' 'sink'
                    @ctx.beginPath()
                    @ctx.arc x, y, sz*building.size/2, 0, 2 * Math.PI, false
                    @ctx.fill() 
                when 'triangle'
                    bh = sh*building.size
                    @ctx.beginPath()
                    @ctx.moveTo x-bh, y+bh
                    @ctx.lineTo x+bh, y+bh
                    @ctx.lineTo x,    y-bh
                    @ctx.lineTo x-bh, y+bh
                    @ctx.fill()     
                when 'diamond'
                    bh = sh*building.size
                    @ctx.beginPath()
                    @ctx.moveTo x,    y+bh
                    @ctx.lineTo x+bh, y
                    @ctx.lineTo x,    y-bh
                    @ctx.lineTo x-bh, y
                    @ctx.lineTo x,    y+bh
                    @ctx.fill() 
                when 'rect'
                    bh = sh*building.size
                    @ctx.fillRect x-bh, y-bh, 2*bh, 2*bh
                else            
                    @ctx.fillRect x-sz*building.size/2, y-sz*building.size/2, sz*building.size, sz*building.size
            
    onStash: =>
    
        window.stash.set 'network' @network.serialize()
        
    onRestore: => 
        
        @network.deserialize window.stash.get 'network'
        
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
