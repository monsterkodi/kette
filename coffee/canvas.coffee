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
    
    @: (@parent) ->
        
        @zoom = 
            resetOffsetX:   300
            value:          1.0       # current zoom value
            default:        1.0       # value used when zoom is reset
            max:            50        # maximum value of magnification
            min:            0.01      # minimum value of minification
            zeroPrice:      0         # price at canvas coordinate system origin
            viewCenter:     kpos 0 0  # offset from lastKline in unscaled canvas coordinates
        
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
             
        klog newZoom
        if @zoom.value != newZoom
                 
            @zoomAtViewPos newZoom, eventPos
                         
    # 0000000   0000000    0000000   00     00  
    #    000   000   000  000   000  000   000  
    #   000    000   000  000   000  000000000  
    #  000     000   000  000   000  000 0 000  
    # 0000000   0000000    0000000   000   000  
    
    zoomAtViewPos: (newZoom, viewPos) ->
           
        center = viewPos.times 2
        # ref = kpos @tickX(@numKlines-1), @priceY @zoom.zeroPrice
        ref = kpos 0 0
        @zoom.viewCenter.add (ref.plus (center.minus ref).scale newZoom / @zoom.value).sub center
        
        @setZoomScale newZoom
                
    setZoomScale: (newZoom) ->

        @zoom.value = newZoom
        
        @redraw()
        
    moveByViewDelta: (delta) -> 
    
        @zoom.viewCenter.sub delta.times 2
        @redraw()
    
    resetZoom: =>
        
        @zoom.value = 1
        @zoom.viewCenter.x = @zoom.resetOffsetX
        @zoom.viewCenter.y = @height * (@currentPrice() - @dataMid) / @dataRange / 2
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

        if @dirty
            @clear()
            @draw()
            @dirty = false
            
    draw: ->
        klog @width, @height
        @ctx.fillStyle = '#ff1'
        @ctx.fillRect @zoom.value*@width/4, @zoom.value*@height/4, @zoom.value*@width/2, @zoom.value*@height/2
                
    #  0000000  000000000   0000000    0000000  000   000  
    # 000          000     000   000  000       000   000  
    # 0000000      000     000000000  0000000   000000000  
    #      000     000     000   000       000  000   000  
    # 0000000      000     000   000  0000000   000   000  
    
    onStash: =>
                
        stash = window.stash
        
    onRestore: =>
        
        stash = window.stash
        
    onMenuAction: (action, args) ->
        
        switch action 
            when 'reset zoom'           then return @resetZoom()
            
        'unhandled'
        
    # 000   000  00000000  000   000    
    # 000  000   000        000 000     
    # 0000000    0000000     00000      
    # 000  000   000          000       
    # 000   000  00000000     000       
        
    modKeyComboEventDown: (mod, key, combo, event) ->
        
        switch combo
            when "command+0"    then @resetAvgScale()
            when 'command+='    then @increaseAvgScale()
            when 'command+-'    then @decreaseAvgScale()
                
module.exports = Canvas
