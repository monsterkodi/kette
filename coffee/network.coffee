###
000   000  00000000  000000000  000   000   0000000   00000000   000   000  
0000  000  000          000     000 0 000  000   000  000   000  000  000   
000 0 000  0000000      000     000000000  000   000  0000000    0000000    
000  0000  000          000     000   000  000   000  000   000  000  000   
000   000  00000000     000     00     00   0000000   000   000  000   000  
###

{ clamp, kpos, kstr } = require 'kxk'
{ lpad, rpad, pad } = kstr
{ max, min } = Math

class Network

    @: -> 
        
        @pause = false
        @step  = 0
        @speed = 1
        @epoch = 0.0
        @epoch_incr = 0.1
        @belts = []
        @items = []
        @nodes = []
        @buildings = []
        
        @colidx = 0
        @shapeidx = 0
        @colors = ['#aaf' '#f00' '#ff0']
        @shapes = ['circle' 'rect' 'triangle' 'diamond']
        
        @init()
        
    build: (type, pos) -> 
    
        building = switch type
            when 'miner'   then new Miner   pos, @newNode pos
            when 'painter' then new Painter pos, @newNode pos
            when 'builder' then new Builder pos, @newNode pos
            when 'sink'    then new Sink    pos, @newNode pos
            else null
        
        if building
            building.node.building = building
            @buildings.push building
            building

    init: ->
        
        p1 = kpos -20   0
        p2 = kpos   0   0
        p3 = kpos  70   0
        p4 = kpos  70 -90
        p5 = kpos   0 -90
        p6 = kpos   0  90
        
        belt0 = @addBelt 1, p1, p2
        belt1 = @addBelt 1, p2, p3
        belt2 = @addBelt 1, p3, p4
        belt3 = @addBelt 1, p4, p5
        belt4 = @addBelt 1, p2, p5
        belt5 = @addBelt 1, p2, p6
        
        @connect belt0, belt1
        @connect belt1, belt2
        @connect belt2, belt3
        @addNode belt3
        
        @nodes[-1].addInp belt4
        belt4.out = @nodes[-1]
        
        @nodes[0].addOut belt4
        belt4.inp = @nodes[0]
        
        @nodes[0].addOut belt5
        belt5.inp = @nodes[0]
        
        @addNode belt5
        
    addBelt: (speed, p1, p2) ->
        
        belt = new Belt speed, p1, p2
        belt.epoch = @epoch
        @belts.push belt
        belt

    newNode: (pos) ->
        
        node = new Node pos
        @nodes.push node
        node
        
    addNode: (belt) ->
        
        node = @newNode belt.p2
        node.addInp belt
        belt.out = node
        node
                
    connect: (belt1, belt2) ->
        
        node = @newNode belt1.p2
        node.addInp belt1
        node.addOut belt2
        belt1.out = node
        belt2.inp = node
        node
        
    newItemOnBelt: (belt) ->
        
        if not belt.tail or belt.tail.pos >= 1
            item = new Item belt

            @colidx = (@colidx+1)%@colors.length
            item.color = @colors[@colidx]

            @shapeidx = (@shapeidx+1)%@shapes.length
            item.shape = @shapes[@shapeidx]
            
            @items.push item
            
            belt.add item
            
    clear: ->
        
        @items = []
        for belt in @belts
            belt.head = null
            belt.tail = null
                
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
        
        if not @pause or @doStep
            @doStep = false
            for i in 0...@speed
                @step += 1
                @nextStep()
        
    togglePause: -> @pause = not @pause
    
    addToSpeed: (delta) -> @speed = clamp 1 10 @speed + delta
    
    nodeAtPos: (pos) ->
        
        for node in @nodes
            if node.pos.dist(pos) < 0.5
                return node
      
    beltAtPos: (pos) ->
        
        for belt in @belts
            if belt.p2.dist(pos) < 0.5
                return belt
            if belt.p1.dist(pos) < 0.5
                return belt
                    
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
            
            if @out and headPos >= @length
                @out.dispatch @, epoch_incr
                if not @head then return
                    
            headRoom = @length - @head.pos
            
            headMove = max 0 min @speed * epoch_incr, headRoom
            @head.pos += headMove
            
            item = @head
            while prev = item.prev
                itemRoom = item.pos - 1 - prev.pos
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
    
    @: (@pos) ->
        
        @inp = []
        @out = []
        
        @inpidx = 0
        @outidx = 0
        
        @building = null
        
    addInp: (belt) -> @inp.push belt
    addOut: (belt) -> @out.push belt
    
    dispatch: (belt, epoch_incr) ->
        
        if @building?.dispatch(belt) then return
        
        if @inp.length == 0 or @out.length == 0 then return
        
        @outidx += 1
        @outidx %= @out.length
        out = @out[@outidx]

        if (not out.tail) or out.tail.pos >= 1
            tailRoom = if out.tail then out.tail.pos-1 else out.length
            epoch_fact = 1.0 - ((belt.length - belt.head.pos) / (epoch_incr))
            epoch_rest = epoch_incr * epoch_fact
            out.add belt.pop()
            if belt.epoch < out.epoch
                out.tail.pos += max 0 min out.speed * epoch_rest, tailRoom
                
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
             
class Miner
    
    @: (@pos, @node) -> 
    
        @type  ='miner'
        @color = '#fff'
        @size  = 2
        
        delete @node.inp
    
    dispatch: (belt) -> false

class Sink
    
    @: (@pos, @node) -> 
    
        @type   ='sink'
        @color  = '#333' 
        @size   = 2
        
        delete @node.out
    
    dispatch: (belt) -> 

        belt.pop() 
        true

class Painter
    
    @: (@pos, @node) -> @color = '#8886'; @size = 2; @type='painter'
    
    dispatch: (belt) -> belt.head.color = '#ff0'; false

class Builder
    
    @: (@pos, @node) -> @color = '#8886'; @size = 3; @type='builder'
    
    dispatch: (belt) -> false
    
module.exports = Network
