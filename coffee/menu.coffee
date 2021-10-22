###
00     00  00000000  000   000  000   000
000   000  000       0000  000  000   000
000000000  0000000   000 0 000  000   000
000 0 000  000       000  0000  000   000
000   000  00000000  000   000   0000000 
###

{ $, elem } = require 'kxk'

class Menu

    @: (@pos) ->
        
        main  =$ '#main'
        
        @div = elem class:'buildMenu' parent:main, style:"top:#{@pos.y}px; left:#{@pos.x}px"
        
        itm = elem class:'buildItem' text:'1' parent:@div
        itm = elem class:'buildItem' text:'2' parent:@div
        itm = elem class:'buildItem' text:'3' parent:@div
        itm = elem class:'buildItem' text:'4' parent:@div
        
        main.addEventListener 'mouseup' @onMouseUp
      
    close: => 
    
        @div.remove()
        main.removeEventListener 'mouseup' @onMouseUp
        
    onMouseUp: => @close()
        
module.exports = Menu
