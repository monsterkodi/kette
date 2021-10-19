###
00     00   0000000   000  000   000
000   000  000   000  000  0000  000
000000000  000000000  000  000 0 000
000 0 000  000   000  000  000  0000
000   000  000   000  000  000   000
###

{ kstr } = require 'kxk'
{ lpad, rpad, pad } = kstr
{ max, min } = Math

class Main

    @: -> 
        
        @step  = 0
        @epoch = 0.0
        @belts = []
        @items = []
        @nodes = []
    
    init: ->
        
        belt = new Belt @epoch, 10, 0.88
        @belts.push belt

        @newItemOnBelt belt
        
        belt2 = new Belt @epoch, 5, 0.5
        @belts.push belt2
        
        @connect belt, belt2
        
        @dump()
        
    connect: (belt1, belt2) ->
        
        node = new Node 
        @nodes.push node
        node.addInp belt1
        node.addOut belt2
        belt1.out = node
        belt2.inp = node
        
    newItemOnBelt: (belt) ->
        
        item = new Item belt
        @items.push item
        
        belt.add item
                
    run: ->
        
        @epoch_incr = 0.2
        
        for @step in 1..200
                
            if @step == 40 or @step == 80
                @newItemOnBelt @belts[0]
            
            @epoch += @epoch_incr
            for belt in @belts
                belt.advance @epoch_incr
                
            for node in @nodes
                node.process()
                
            @dump()
                    
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

class Item
    
    @: ->
    
        @pos  = 0.0
        @prev = null
    
class Belt
    
    @: (@epoch, @length, @speed=1) ->
        
        @head   = null
        @tail   = null
        
        @inp    = null
        @out    = null
        
    advance: (epoch_incr) ->
        
        if @head
            headRoom = @length - @head.pos
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
        
class Node
    
    @: ->
        
        @inp = []
        @out = []
        
    addInp: (belt) -> @inp.push belt
    addOut: (belt) -> @out.push belt
    
    process: ->
        
        inp = @inp[0]
        out = @out[0]
        if inp and out
            if item = inp.head
                if item.pos == inp.length
                    if not out.tail or out.tail.pos >= 1
                        out.add inp.pop()
        
m = new Main()
m.init()
m.run()
