###
000   000  00000000  000000000  000   000   0000000   00000000   000   000  
0000  000  000          000     000 0 000  000   000  000   000  000  000   
000 0 000  0000000      000     000000000  000   000  0000000    0000000    
000  0000  000          000     000   000  000   000  000   000  000  000   
000   000  00000000     000     00     00   0000000   000   000  000   000  
###

{ clamp, klog, kpos, kstr, noon } = require 'kxk'
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
        
    newBuilding: (type, pos, node) -> 
    
        if not node then node = @nodeAtPos pos
        
        if node 
            if node.building
                @deleteAtPos pos
        else
            node = @newNode pos
                
        building = switch type
            when 'miner'                     then new Miner   pos, node
            when 'crafter'                   then new Crafter pos, node
            when 'sink'                      then new Sink    pos, node
            when 'rect' 'triangle' 'diamond' then new Shaper  pos, node, type
            when 'red' 'green' 'blue'        then new Painter pos, node, type
            else null
        
        if building
            
            if building.type == 'miner'
                @miners.push building
            
            building.node.building = building
            @buildings.push building
            building

    newBelt: (inp, out) ->
        
        belt = new Belt inp, out
        inp.addOut belt
        out.addInp belt
        belt.epoch = @epoch
        @belts.push belt
        belt

    newNode: (pos) ->
        
        node = new Node pos
        @nodes.push node
        node
                            
    clear: ->
        
        for belt in @belts
            belt.head = null
            belt.tail = null
            
        for node in @nodes
            node.queue = []
           
    # 0000000    00000000  000      00000000  000000000  00000000  
    # 000   000  000       000      000          000     000       
    # 000   000  0000000   000      0000000      000     0000000   
    # 000   000  000       000      000          000     000       
    # 0000000    00000000  0000000  00000000     000     00000000  
    
    deleteAtPos: (pos) ->
        
        if node = @nodeAtPos pos
            if node.building
                if @miners.indexOf(node.building) >= 0
                    @miners.splice @miners.indexOf(node.building), 1
                @buildings.splice @buildings.indexOf(node.building), 1
                delete node.building
                if not node.out then node.out = []
                if not node.inp then node.inp = []
            else
                for b in node.out
                    b.out.inp.splice b.out.inp.indexOf(b), 1
                    @belts.splice @belts.indexOf(b), 1
                for b in node.inp
                    b.inp.out.splice b.inp.out.indexOf(b), 1
                    @belts.splice @belts.indexOf(b), 1
                @nodes.splice @nodes.indexOf(node), 1
            
    destroy: ->
        
        @step       = 0
        @epoch      = 0.0
        @belts      = []
        @nodes      = []
        @buildings  = []
        @miners     = []
            
    #  0000000  00000000  00000000   000   0000000   000      000  0000000  00000000  
    # 000       000       000   000  000  000   000  000      000     000   000       
    # 0000000   0000000   0000000    000  000000000  000      000    000    0000000   
    #      000  000       000   000  000  000   000  000      000   000     000       
    # 0000000   00000000  000   000  000  000   000  0000000  000  0000000  00000000  
    
    serialize: ->
        
        s = noon.stringify
            nodes: (n.data() for n in @nodes)
            buildings: (b.data() for b in @buildings)
        s
        
    deserialize: (str) ->
        
        @destroy()
        
        s = noon.parse str
        
        return if not s?.nodes
        
        bs = []
        for n in s.nodes
            node = @newNode kpos n.x, n.y
            if n.o?
                for o in n.o
                    bs.push x:n.x, y:n.y, o:o
               
        for b in bs
            inp  = @nodeAtPos kpos b
            out  = @nodeAtPos kpos b.o
            belt = @newBelt inp, out
            
        for b in s.buildings
            p = kpos b
            @newBuilding b.t, p, @nodeAtPos p
            
        if @serialize() != str
            klog 'dafuk?' str, @serialize()
                
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
      
# 0000000    00000000  000      000000000  
# 000   000  000       000         000     
# 0000000    0000000   000         000     
# 000   000  000       000         000     
# 0000000    00000000  0000000     000     

class Belt
    
    @: (@inp, @out) ->
        
        @speed  = 1
        @length = @inp.pos.to(@out.pos).length()
        
        @head   = null
        @tail   = null
        
        @epoch  = 0
        
    advance: (epoch_incr) ->
        
        @epoch += epoch_incr
        
        if @head
            
            headPos = @head.pos + @speed * epoch_incr
            
            if @out and headPos >= @length-1
                @out.dispatch @, epoch_incr
                if not @head then return
                    
            headRoom = @length - 1 - @head.pos
            
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
        if not @head then @head = item
        if @tail then @tail.prev = item
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
        
        @inp   = []
        @out   = []
        @queue = []
        
        @inpidx = 0
        @outidx = 0
        
        @building = null
        
    data: -> 
        
        d = 
            x:@pos.x 
            y:@pos.y
        if @out?
            d.o = []
            for b in @out
                d.o.push x:b.out.pos.x, y:b.out.pos.y
        d
        
    addInp: (belt) -> @inp.push belt
    addOut: (belt) -> @out.push belt
    
    dispatch: (belt, epoch_incr) ->
        
        return if @building?.dispatch(belt)
        
        return if not @out
        
        return if @inp.length == 0 or @out.length == 0  
        
        minTailRoom = Infinity
        for out in @out
            minTailRoom = min minTailRoom, if out.tail then out.tail.pos-1 else out.length
        
        if @queue.length == 0 or @queue[0] == belt
            headRoom = belt.length - belt.head.pos  
            headRoom += minTailRoom
            belt.head.pos += max 0 min belt.speed * epoch_incr, headRoom
            if belt.head.pos >= belt.length
                
                @outidx += 1
                @outidx %= @out.length
                out = @out[@outidx]
                
                out.add belt.pop()
                if belt.epoch < out.epoch
                    out.tail.pos += max 0 belt.speed * epoch_incr - headMove
                if @queue[0] == belt then @queue.shift()
                return
        if belt not in @queue
            @queue.push belt
    
# 000  000000000  00000000  00     00  
# 000     000     000       000   000  
# 000     000     0000000   000000000  
# 000     000     000       000 0 000  
# 000     000     00000000  000   000  

class Item
    
    @: ->
    
        @pos  = 0.0
        @prev = null
           
class Building
    
    dispatch: (belt) -> false
    data: -> 
        t: @type
        x: @pos.x
        y: @pos.y
        
class Miner extends Building
    
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
    
class Sink extends Building
    
    @: (@pos, @node) -> 
    
        @type   ='sink'
        @color  = '#333' 
        @size   = 2
        
        delete @node.out
    
    dispatch: (belt) -> 

        belt.pop() 
        true

class Painter extends Building
    
    @: (@pos, @node, @type) -> 
    
        @size  = 2
        
        @paint = switch @type
            when 'red'   then '#f00'
            when 'green' then '#0f0'
            when 'blue'  then '#00f'
    
        @color = @paint + 'a'
        
    dispatch: (belt) -> belt.head.color = @paint; false

class Shaper extends Building
    
    @: (@pos, @node, @type) -> 
    
        @color = '#8886' 
        @size  = 3 
    
class Crafter extends Building
    
    @: (@pos, @node) -> @color = '#8886'; @size = 4; @type='crafter'
        
module.exports = Network
