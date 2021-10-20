###
000   000  00000000  000000000  000   000   0000000   00000000   000   000  
0000  000  000          000     000 0 000  000   000  000   000  000  000   
000 0 000  0000000      000     000000000  000   000  0000000    0000000    
000  0000  000          000     000   000  000   000  000   000  000  000   
000   000  00000000     000     00     00   0000000   000   000  000   000  
###

{ kpos, kstr } = require 'kxk'
{ lpad, rpad, pad } = kstr
{ max, min } = Math

class Network

    @: -> 
        
        @pause = false
        @step  = 0
        @epoch = 0.0
        @epoch_incr = 0.1
        @belts = []
        @items = []
        @nodes = []
        
        @colidx = 0
        @colors = ["#88f8" "#f608"]
        
        @init()

    init: ->
        
        belt0 = @addBelt 1, kpos(-10,0), kpos(0,0)

        belt1 = @addBelt 1, kpos(0,0), kpos(10,0)
        
        @connect belt0, belt1
        
        belt2 = @addBelt 1, kpos(10,0), kpos(10,-10)
        
        @connect belt1, belt2
        
        belt3 = @addBelt 1, kpos(10,-10), kpos(0,-10)
        
        @connect belt2, belt3
        
        belt4 = @addBelt 1, kpos(0,-10), kpos(0,0)
        
        @connect belt3, belt4
        
        @nodes[0].addInp belt4
        belt4.out = @nodes[0]
        
        belt5 = @addBelt 1, kpos(0,0), kpos(0,10)
        
        @nodes[0].addOut belt5
        belt5.inp = @nodes[0]
        
    addBelt: (speed, p1, p2) ->
        
        belt = new Belt speed, p1, p2
        @belts.push belt
        belt
        
    connect: (belt1, belt2) ->
        
        node = new Node 
        @nodes.push node
        node.addInp belt1
        node.addOut belt2
        belt1.out = node
        belt2.inp = node
        
    newItemOnBelt: (belt) ->
        
        if not belt.tail or belt.tail.pos >= 1
            item = new Item belt
            @colidx = (@colidx+1)%@colors.length
            item.color = @colors[@colidx]
            @items.push item
            
            belt.add item
                
    #  0000000  000000000  00000000  00000000   
    # 000          000     000       000   000  
    # 0000000      000     0000000   00000000   
    #      000     000     000       000        
    # 0000000      000     00000000  000        
    
    nextStep: ->
        
        @newItemOnBelt @belts[0]
                    
        @epoch += @epoch_incr
        
        for belt in @belts
            belt.advance @epoch_incr
                        
    onAnimationFrame: ->
        
        if not @pause
            @step += 1
            @nextStep()
        if @doStep
            @step += 1
            @nextStep()
            @doStep = false
        
    togglePause: -> @pause = not @pause
                    
    dump: ->
        
        str = "#{lpad @step, 3} #{lpad @epoch.toFixed(1), 4}"
        
        for belt in @belts
            its = ''
            item = belt.head
            while item
                its += "#{lpad item.pos.toFixed(2), 6} "
                item = item.prev
            str += " #{@belts.indexOf(belt)}:[#{its}]"
        
        log str
    
# 0000000    00000000  000      000000000  
# 000   000  000       000         000     
# 0000000    0000000   000         000     
# 000   000  000       000         000     
# 0000000    00000000  0000000     000     

class Belt
    
    @: (@speed, @p1, @p2) ->
        
        @length = @p1.to(@p2).length()
        
        @head   = null
        @tail   = null
        
        @inp    = null
        @out    = null
        
        @epoch  = 0
        
    advance: (epoch_incr) ->
        
        @epoch += epoch_incr
        
        if @head
            
            headPos = @head.pos + @speed * epoch_incr
            
            if @out and @length - headPos <= 0
                @out.dispatch @, epoch_incr
                if not @head then return
                    
            headRoom = @length - @head.pos
            tailGap = @out?.tailGap(@) or 0
            
            headRoom -= tailGap
            
            headMove = max 0 min @speed * epoch_incr, headRoom
            @head.pos += headMove
            
            item = @head
            while prev = item.prev
                itemRoom = item.pos - prev.pos - 1
                prevMove = max 0 min @speed * epoch_incr, itemRoom
                prev.pos += prevMove
                item = prev
                
    add: (item) ->
        
        item.pos = 0.0
        item.prev = null
        if not @head
            @head = item
        if @tail
            @tail.prev = item
        @tail = item
        
    pop: ->
        
        item = @head
        
        @head = item.prev
        if not @head then @tail = null
        
        item
        
# 000   000   0000000   0000000    00000000  
# 0000  000  000   000  000   000  000       
# 000 0 000  000   000  000   000  0000000   
# 000  0000  000   000  000   000  000       
# 000   000   0000000   0000000    00000000  

class Node
    
    @: ->
        
        @inp = []
        @out = []
        
        @inpidx = 0
        @outidx = 0
        
    addInp: (belt) -> @inp.push belt
    addOut: (belt) -> @out.push belt
    
    dispatch: (belt, epoch_incr) ->
        
        if @inp.length == 0 or @out.length == 0 then return
        
        @outidx += 1
        @outidx %= @out.length
        out = @out[@outidx]

        if not out.tail or out.tail.pos >= 1
            tailRoom = if out.tail then out.tail.pos-1 else out.length
            epoch_fact = 1.0 - ((belt.length - belt.head.pos) / (epoch_incr))
            epoch_rest = epoch_incr * epoch_fact
            out.add belt.pop()
            if belt.epoch < out.epoch
                out.tail.pos += max 0 min out.speed * epoch_rest, tailRoom
            return
    
    tailGap: (input) ->
        
        gap = 0
        if @out.length
            for oi in 0...@out.length
                if @out[oi].tail and @out[oi].tail.pos < 1
                    gap = max gap, 1 - @out[oi].tail.pos
                        
        if @inp.length
            for ii in 0...@inp.length
                if @inp[ii] != input
                    if @inp[ii].head and @inp[ii].head.pos > @inp[ii].length-1
                        if @inp[ii].length - @inp[ii].head.pos < input.length - input.head.pos
                            return 1
        gap
                        
# 000  000000000  00000000  00     00  
# 000     000     000       000   000  
# 000     000     0000000   000000000  
# 000     000     000       000 0 000  
# 000     000     00000000  000   000  

class Item
    
    @: ->
    
        @pos  = 0.0
        @prev = null
                        
module.exports = Network
