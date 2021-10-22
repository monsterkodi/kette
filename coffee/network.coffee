###
000   000  00000000  000000000  000   000   0000000   00000000   000   000  
0000  000  000          000     000 0 000  000   000  000   000  000  000   
000 0 000  0000000      000     000000000  000   000  0000000    0000000    
000  0000  000          000     000   000  000   000  000   000  000  000   
000   000  00000000     000     00     00   0000000   000   000  000   000  
###

{ clamp, kstr } = require 'kxk'
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
        @nodes = []
        @buildings = []
        @miners = []
        
        @colidx = 0
        @shapeidx = 0
        @colors = ['#aaf' '#f00' '#ff0']
        @shapes = ['circle' 'rect' 'triangle' 'diamond']
        
    build: (type, pos) -> 
    
        newNode = @newNode pos
        building = switch type
            when 'miner'   then new Miner   pos, newNode
            when 'builder' then new Builder pos, newNode
            when 'sink'    then new Sink    pos, newNode
            when 'red' 'green' 'blue' then new Painter pos, newNode, type
            else null
        
        if building
            
            if building.type == 'miner'
                @miners.push building
            
            building.node.building = building
            @buildings.push building
            building

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
                    
    clear: ->
        
        for belt in @belts
            belt.head = null
            belt.tail = null
                
    #  0000000  000000000  00000000  00000000   
    # 000          000     000       000   000  
    # 0000000      000     0000000   00000000   
    #      000     000     000       000        
    # 0000000      000     00000000  000        
    
    nextStep: ->
        
        @step  += 1
        @epoch += @epoch_incr
        
        for miner in @miners
            miner.createItem @step
        
        for belt in @belts
            belt.advance @epoch_incr
                        
    onAnimationFrame: ->
        
        if not @pause or @doStep
            @doStep = false
            for i in 0...@speed
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
    
        @type   ='miner'
        @color  = '#fff'
        @size   = 2
        @outidx = 0
        
        delete @node.inp
        
    createItem: (step) ->

        numOut = @node.out.length
        
        if step % 20 == 0 and numOut
                
            @outidx += 1
            @outidx %= numOut
            
            for i in 0...numOut
                belt = @node.out[(@outidx+i)%numOut]
                if not belt.tail or belt.tail.pos >= 1
                    item = new Item belt
                    item.color = "#888"
                    item.shape = 'circle'
                    belt.add item
                    return
    
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
    
    @: (@pos, @node, colorKey) -> 
    
        @type  ='painter'
        @size  = 2
        
        @paint = switch colorKey
            when 'red'   then '#f00'
            when 'green' then '#0f0'
            when 'blue'  then '#00f'
    
        @color = @paint + '6'
        
    dispatch: (belt) -> belt.head.color = @paint; false

class Builder
    
    @: (@pos, @node) -> @color = '#8886'; @size = 3; @type='builder'
    
    dispatch: (belt) -> false
    
module.exports = Network
