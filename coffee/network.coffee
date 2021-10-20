###
000   000  00000000  000000000  000   000   0000000   00000000   000   000  
0000  000  000          000     000 0 000  000   000  000   000  000  000   
000 0 000  0000000      000     000000000  000   000  0000000    0000000    
000  0000  000          000     000   000  000   000  000   000  000  000   
000   000  00000000     000     00     00   0000000   000   000  000   000  
###

{ kpos, kstr, last } = require 'kxk'
{ lpad, rpad, pad } = kstr
{ max, min } = Math

class Network

    @: -> 
        
        @pause = false
        @step  = 0
        @epoch = 0.0
        @epoch_incr = 0.04
        @belts = []
        @items = []
        @nodes = []
        
        @colidx = 0
        @colors = ["#88f" "#f60"]
        
        @init()
    
    init: ->
        
        belt = new Belt 1, kpos(-10,0), kpos(0,0)
        @belts.push belt

        belt1 = new Belt 1, kpos(0,0), kpos(10,0)
        @belts.push belt1
        
        @connect belt, belt1
        
        @newItemOnBelt belt
        
        belt2 = new Belt 1, kpos(10,0), kpos(10,-10)
        @belts.push belt2
        
        @connect belt1, belt2
        
        @dump()
        
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
                
    run: ->
        
        for @step in 1..100
            @nextStep()
                
    #  0000000  000000000  00000000  00000000   
    # 000          000     000       000   000  
    # 0000000      000     0000000   00000000   
    #      000     000     000       000        
    # 0000000      000     00000000  000        
    
    nextStep: ->
        
        # if @step % 10 == 0
        @newItemOnBelt @belts[0]
            
        if @step == 30
            last = @belts[-1]
            belt = new Belt 1, kpos(10,-10), kpos(0,-10)
            @belts.push belt
            @connect last, belt
            
            belt2 = new Belt 1, kpos(0,-10), kpos(0,0)
            @belts.push belt2
            @connect belt, belt2
            
            @nodes[0].addInp belt2
            belt2.out = @nodes[0]
        
        @epoch += @epoch_incr
        
        for node in @nodes
            node.process()
        
        for belt in @belts
            belt.advance @epoch_incr
                        
        # @dump()
            
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
        
    advance: (epoch_incr) ->
        
        if @head
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
    
    tailGap: (input) ->
        
        gap = 0
        if @out.length
            for oi in 0...@out.length
                if @out[oi].tail and @out[oi].tail.pos < 1
                    gap = max gap, 1 - @out[oi].tail.pos
                    # if @inp.length > 1
                        # log gap
                        
        if @inp.length
            for ii in 0...@inp.length
                if @inp[ii] != input
                    if @inp[ii].head and @inp[ii].head.pos > @inp[ii].length-1
                        if @inp[ii].length - @inp[ii].head.pos < input.length - input.head.pos
                            return 1
            
        gap
    
    process: ->
        
        if @inp.length == 0 or @out.length == 0 then return
        
        # @inpidx += 1
        @outidx += 1
#         
        # @inpidx %= @inp.length
        @outidx %= @out.length
#                 
        # inp = @inp[@inpidx]
        out = @out[@outidx]

        # if item = inp.head
            # if item.pos == inp.length
                # if not out.tail or out.tail.pos >= 1
                    # out.add inp.pop()

        for ii in 0...@inp.length
            inp = @inp[ii]
            if item = inp.head
                if item.pos == inp.length
                    if not out.tail or out.tail.pos >= 1
                        out.add inp.pop()
                        return
                    
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
