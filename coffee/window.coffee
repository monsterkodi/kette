###
000   000  000  000   000  0000000     0000000   000   000
000 0 000  000  0000  000  000   000  000   000  000 0 000
000000000  000  000 0 000  000   000  000   000  000000000
000   000  000  000  0000  000   000  000   000  000   000
00     00  000  000   000  0000000     0000000   00     00
###

{ $, args, kerror, keyinfo, klog, kpos, post, stash, win } = require 'kxk'

Canvas  = require './canvas'
Network = require './network'

class MainWin extends win
    
    @: ->
        
        super
            dir:    __dirname
            pkg:    require '../package.json'
            menu:   '../coffee/menu.noon'
            icon:   '../img/mini.png'
            prefsSeperator: '▸'
            onLoad: @onLoad
            
        post.on 'alert' (msg) -> window.alert(msg); kerror msg
        post.on 'saveStash'   @saveStash
        
        window.stash = new stash "win/#{@id}" separator:'|'
        post.setMaxListeners 20
        
        window.onload = @onLoad
                                    
    # 000       0000000    0000000   0000000    
    # 000      000   000  000   000  000   000  
    # 000      000   000  000000000  000   000  
    # 000      000   000  000   000  000   000  
    # 0000000   0000000   000   000  0000000    
    
    onLoad: =>
        
        @main  =$ '#main'
        @network = new Network()
        @canvas = new Canvas @main, @network
        
        # @win.on 'focus'     @onFocus
        # @win.on 'blur'      @onBlur
        # @win.on 'close'     @onClose
        # @win.on 'move'      @onMove
        
        post.emit 'resize'
        
        window.onresize = @onResize

        window.addEventListener 'beforeunload' @onBeforeUnload
        
        @restore()
        
        window.requestAnimationFrame @onAnimationFrame
           
    onFocus: => 
    onBlur:  => 
    onMouseEnter: => 
        
    onAnimationFrame: (timestamp) =>

        @network.onAnimationFrame()
        @canvas.onAnimationFrame()
        window.requestAnimationFrame @onAnimationFrame

    onMove: => window.stash.set 'bounds' @getBounds()
    
    onResize: =>
        
        window.stash.set 'bounds' @getBounds()
        post.emit 'resize'
        
    clearListeners: ->
            
        window.document.onmouseenter = null
        window.removeEventListener 'beforeunload' @onBeforeUnload

    onBeforeUnload: (event) => @clearListeners()
    
    # onClose: =>
#     
        # if electron.remote.BrowserWindow.getAllWindows().length > 1
            # window.stash.clear()
#             
        # @clearListeners()
        
    # 00000000   00000000   0000000  000000000   0000000   00000000   00000000  
    # 000   000  000       000          000     000   000  000   000  000       
    # 0000000    0000000   0000000      000     000   000  0000000    0000000   
    # 000   000  000            000     000     000   000  000   000  000       
    # 000   000  00000000  0000000      000      0000000   000   000  00000000  
    
    restore: =>
    
        if bounds = window.stash.get 'bounds'
            @setBounds bounds
    
        post.emit 'restore'
   
    saveStash: =>
    
        window.stash.set 'bounds' @getBounds()
        post.emit 'stash'
        window.stash.save()
        post.toMain 'stashSaved'
        
    # 000   000  00000000  000   000  
    # 000  000   000        000 000   
    # 0000000    0000000     00000    
    # 000  000   000          000     
    # 000   000  00000000     000     
    
    onKeyDown: (event) =>

        { mod, key, combo } = keyinfo.forEvent event
        @canvas?.modKeyComboEventDown mod, key, combo, event
        super
        
    # 00     00  00000000  000   000  000   000  
    # 000   000  000       0000  000  000   000  
    # 000000000  0000000   000 0 000  000   000  
    # 000 0 000  000       000  0000  000   000  
    # 000   000  00000000  000   000   0000000   
    
    onMenuAction: (action, args) =>
               
        switch action.toLowerCase()
            when 'delete'       then return @network.deleteAtPos @canvas.mousePos
            when 'save'         then return @saveStash()
            when 'destroy'      then @network.destroy(); @canvas.resetZoom(); return @network.newBuilding 'miner' kpos 0 0
            when 'revert'       then return @restore()
            when 'pause'        then return @network.togglePause()
            when 'step'         then return @network.doStep = true
            when 'speed down'   then return @network.addToSpeed -1
            when 'speed up'     then return @network.addToSpeed 1
            when 'clear'        then return @network.clear()
            when 'new window'
                @saveStash()
                return repost 'New Window' @id
            when 'red' 'green' 'blue' then return @network.newBuilding action, @canvas.mousePos
            when 'rect' 'triangle' 'diamond' then return @network.newBuilding action, @canvas.mousePos
            when 'miner' 'crafter' 'sink' then return @network.newBuilding action, @canvas.mousePos
            
        if @canvas
            return if 'unhandled' != @canvas.onMenuAction action, args
            
        klog "menuAction '#{action}'" # args     
        super
           
new MainWin            
