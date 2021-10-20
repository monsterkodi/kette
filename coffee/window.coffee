###
000   000  000  000   000  0000000     0000000   000   000
000 0 000  000  0000  000  000   000  000   000  000 0 000
000000000  000  000 0 000  000   000  000   000  000000000
000   000  000  000  0000  000   000  000   000  000   000
00     00  000  000   000  0000000     0000000   00     00
###

{ $, args, kerror, keyinfo, open, post, stash, win } = require 'kxk'

electron = require 'electron'
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
        
        # @win.setHasShadow false    
        
        window.stash = new stash "win/#{@win.id}" separator:'|'
        post.setMaxListeners 20
                                    
    # 000       0000000    0000000   0000000    
    # 000      000   000  000   000  000   000  
    # 000      000   000  000000000  000   000  
    # 000      000   000  000   000  000   000  
    # 0000000   0000000   000   000  0000000    
    
    onLoad: =>
        
        @main  =$ '#main'
        @graph = new Canvas @main

        @network = new Network()
        
        @win.on 'focus'     @onFocus
        @win.on 'blur'      @onBlur
        @win.on 'close'     @onClose
        @win.on 'move'      @onMove
        
        post.emit 'resize'
        
        # window.document.onmouseenter = @onMouseEnter
        window.onresize = @onResize

        window.addEventListener 'beforeunload' @onBeforeUnload
        
        # @restore()
        
        window.requestAnimationFrame @onAnimationFrame
           
    onFocus: => #@graph.setWinFocus true
    onBlur:  => #@graph.setWinFocus false
    onMouseEnter: => 
        #@win.focus()
        #@graph?.canvas?.focus()
        
    onAnimationFrame: =>

        @network.onAnimationFrame()
        @graph.onAnimationFrame()
        window.requestAnimationFrame @onAnimationFrame

    onMove: => window.stash.set 'bounds' @win.getBounds()
    
    onResize: =>
        
        window.stash.set 'bounds' @win.getBounds()
        post.emit 'resize'
        
    clearListeners: ->
    
        @win.removeListener 'resize' @onResize
        @win.removeListener 'focus'  @onFocus
        @win.removeListener 'blur'   @onBlur
        @win.removeListener 'close'  @onClose
        @win.removeListener 'move'   @onMove
        
        window.document.onmouseenter = null
        window.removeEventListener 'beforeunload' @onBeforeUnload

    onBeforeUnload: (event) => @clearListeners()
    
    onClose: =>
    
        if electron.remote.BrowserWindow.getAllWindows().length > 1
            window.stash.clear()
            
        @clearListeners()
        
    # 00000000   00000000   0000000  000000000   0000000   00000000   00000000  
    # 000   000  000       000          000     000   000  000   000  000       
    # 0000000    0000000   0000000      000     000   000  0000000    0000000   
    # 000   000  000            000     000     000   000  000   000  000       
    # 000   000  00000000  0000000      000      0000000   000   000  00000000  
    
    restore: =>
    
        if bounds = window.stash.get 'bounds'
            @win.setBounds bounds
    
        post.emit 'restore'
   
    saveStash: =>
    
        window.stash.set 'bounds' @win.getBounds()
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
        @graph?.modKeyComboEventDown mod, key, combo, event
        super
        
    # 00     00  00000000  000   000  000   000  
    # 000   000  000       0000  000  000   000  
    # 000000000  0000000   000 0 000  000   000  
    # 000 0 000  000       000  0000  000   000  
    # 000   000  00000000  000   000   0000000   
    
    onMenuAction: (action, args) =>
               
        repost = (cmd,args) -> post.emit 'menuAction' cmd, args
        
        # klog "menuAction '#{action}'" # args            
        
        switch action
            when 'save'         then return @saveStash()
            when 'close'        then return @win.close()            
            when 'preferences'  then return open window.stash.file
            when 'screenshot' 'preferences' 'fullscreen' 'about' 'quit' 'about' 'screenshot' 'minimize' 'maximize' 'reload' 'devTools'
                return repost action[0].toUpperCase() + action[1..-1], args 
            when 'toggle menu'  then return repost 'Toggle Menu' args
            # when 'context menu' then return @graph.showContextMenu()
            when 'new window'
                @saveStash()
                return repost 'New Window' @win.id
          
        # if @graph
            # return if 'unhandled' != @graph.onMenuAction action, args
        super
                      
new MainWin            
