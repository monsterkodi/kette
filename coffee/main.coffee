###
00     00   0000000   000  000   000
000   000  000   000  000  0000  000
000000000  000000000  000  000 0 000
000 0 000  000   000  000  000  0000
000   000  000   000  000  000   000
###

{ app, empty, filelist, fs, post, slash, win } = require 'kxk'
{ BrowserWindow } = require 'electron'
{ abs } = Math

wins = -> BrowserWindow.getAllWindows().sort (a,b) -> a.id - b.id

class Main extends app

    @: ->
                
        super
            dir:            __dirname
            pkg:            require '../package.json'
            dirs:           ['../pug' '../styl'] # watch pug and styl
            index:          'index.html'
            icon:           '../img/app.ico'
            about:          '../img/about.png'
            prefsSeperator: '▸'
            width:          1024
            height:         768
            minWidth:       300
            minHeight:      300
            
        @opt.onQuit = @quit
        @opt.onShow = @onShow
        # args.watch  = true
        # args.devtools = true

        @app.on 'window-all-closed' (event) => @exitApp()
        
        @moveWindowStashes()
        post.on 'menuAction' @onMenuAction
        
    onShow: => @restoreWindows()
    hideDock: -> 
                
    #  0000000   000   000  000  000000000  
    # 000   000  000   000  000     000     
    # 000 00 00  000   000  000     000     
    # 000 0000   000   000  000     000     
    #  00000 00   0000000   000     000     
    
    quit: =>

        toSave = wins().length

        if toSave
            post.toWins 'saveStash'
            post.on 'stashSaved' =>
                toSave -= 1
                if toSave == 0
                    @exitApp()
            'delay'
        
    # 00000000   00000000   0000000  000000000   0000000   00000000   00000000
    # 000   000  000       000          000     000   000  000   000  000
    # 0000000    0000000   0000000      000     000   000  0000000    0000000
    # 000   000  000            000     000     000   000  000   000  000
    # 000   000  00000000  0000000      000      0000000   000   000  00000000

    moveWindowStashes: ->
        
        winDir = slash.join @userData, 'win'
        oldDir = slash.join @userData, 'old'
        if slash.dirExists winDir
            fs.moveSync winDir, oldDir, overwrite: true

    restoreWindows: ->
        
        winDir = slash.join @userData, 'win'
        oldDir = slash.join @userData, 'old'
        fs.ensureDirSync oldDir
        stashFiles = filelist oldDir, matchExt:'noon'
        
        if empty stashFiles
            @createWindow()
        else
            for file in stashFiles
                win = @createWindow()
                newStash = slash.join winDir, "#{win.id}.noon"
                fs.copySync file, newStash
            fs.remove oldDir, ->
            
    #  0000000  000       0000000   000   000  00000000  
    # 000       000      000   000  0000  000  000       
    # 000       000      000   000  000 0 000  0000000   
    # 000       000      000   000  000  0000  000       
    #  0000000  0000000   0000000   000   000  00000000  
    
    cloneWinWithId: (winId) ->
        
        winDir = slash.join @userData, 'win'
        win = @createWindow()
        newStash = slash.join winDir, "#{win.id}.noon"
        winStash = slash.join winDir, "#{winId}.noon"
        fs.copySync winStash, newStash
        
    #  0000000    0000000  000000000  000   0000000   000   000  
    # 000   000  000          000     000  000   000  0000  000  
    # 000000000  000          000     000  000   000  000 0 000  
    # 000   000  000          000     000  000   000  000  0000  
    # 000   000   0000000     000     000   0000000   000   000  
    
    onMenuAction: (action, arg) =>

        # klog 'onMenuAction' action, arg
        switch action
            when 'New Window' then return @cloneWinWithId arg
        
new Main
