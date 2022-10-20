require(settings.get("ghu.base") .. "core/apis/ghu")
require("qol")

-- Make sure all reqs are present
-- also move into correct positions
-- ret1: success bool
-- ret2: missing items as table,if failure
function sortReqs()    
    missing = {}
    
    -- Ender Chest
    req = "enderchests:ender_chest"
    res = moveByName(req, 16)
    if (not(res)) then
        missing[req] = true
    end
    
    -- Flux Point
    req = "fluxnetworks:flux_point"
    res = moveByName(req, 15)
    if (not(res)) then
        missing[req] = true
    end
    
    -- Induction Charger
    req = "peripherals:induction_charger"
    res = moveByName(req, 14)
    if (not(res)) then
        missing[req] = true
        print("Debug, ln29")
    end
    
    -- Return missing if any
    if (setLen(missing) > 0) then
        return false, missing
    end
        
    return true
end

-- Mine a square ring 
-- with given radius
-- (
--  radius is amount of blocks from
--  middle block,
--  r=2 therefore makes a 5 wide ring
-- )
-- Can optionally run given callback
-- before every dig.
-- Returns prematurely
-- if callback returns true
-- arg1: int radius
-- arg2: reference to function
-- arg3: table of args to pass to callback
-- ret1: true if returned prematurely
function mineRing(radius, func, args)
    func = func or noop
    args = args or {}
    
    -- Right
    t.turnRight()
    for i=1,radius do
        if(func(unpack(args))) then return true end
        t.dig()
        t.forward()
    end
    t.turnLeft()
    
    -- Down
    for i=1,radius*2 do
        if(func(unpack(args))) then return true end
        t.digDown()
        t.down()
    end
    
    -- Left
    t.turnLeft()
    for i=1,radius*2 do
        if(func(unpack(args))) then return true end
        t.dig()
        t.forward()
    end
    t.turnRight()
    
    -- Up
    for i=1,radius*2 do
        if(func(unpack(args))) then return true end
        t.digUp()
        t.up()
    end

    -- Right
    t.turnRight()
    for i=1,radius do
        if(func(unpack(args))) then return true end
        t.dig()
        t.forward()
        end    
    t.turnLeft()
end

-- See mineRing()
-- This function does the same thing,
-- but also clears out the middle
function mineWall(radius, func, args)
    func = func or noop
    args = args or {}
    
    for r=radius,1,-1 do
        if (mineRing(r, func, args)) then return true end
        t.digDown()
        t.down()
    end
    if (func(unpack(args))) then return true end
    goUp((radius*2)-1)
end
        
-- Function for looking around
-- turtle for specific adjacent
-- block and mining it
-- arg1: string name of block
-- /or/: set of strings
-- ret1: success bool
function mineAdjByName(name) -- TODO: Change name to 'targets'
    -- Turn string into table of strings
    if (type(name) == "string") then
        name = {name = true}
    end
        
    -- Above
    res,block = t.inspectUp()
    if (res) then
        if (name[block["name"]]) then
            t.select(setLen(name))
            t.drop()
            t.digUp()
            name[block["name"]] = nil
            if (setLen(name) == 0) then return true end
        end
    end
    
    -- Below
    res,block = t.inspectDown()
    if (res) then
        if (name[block["name"]]) then
            t.select(setLen(name))
            t.drop()
            t.digDown()
            name[block["name"]] = nil
            if (setLen(name) == 0) then return true end
        end
    end
    
    -- Sides
    for turns=0,3 do
       res,block = t.inspect()
       if (res) then
           if (name[block["name"]]) then
               t.select(setLen(name))
               t.drop()
               t.dig()
               turnL(turns)
               name[block["name"]] = nil
               if (setLen(name) == 0) then return true end
           end
       end
       t.turnRight()
    end
    return false
end

-- Function for mining for specific
-- block in expanding cubes
-- arg1: string blockname
-- arg2: int radius
-- arg3: bool mining other blocks
--       allowed [default false]
-- ret1: success bool
function mineByName(name, radius, mine)
    mABN = mineAdjByName
    mine = mine or false
    
    -- TODO: use these to return to starting pos
    dir = 0
    relative = 0
    
    -- Not mining other blocks is currently not implemented
    if (not(mine)) then 
        print("Running mineByName non-destructively is currently not implemented")
        return false 
    end
    
    -- If radius is 0, this is innermost layer, return false
    if (radius == 0) then return false end
    
    -- Check if the next inner layer finds block
    if (mineByName(name, radius-1, mine)) then return true end
    
    -- Start mining layer
    
    -- Go to end and prepare mining wall
    for i=1,radius do
        if (mABN(name)) then return true end
        t.dig()
        t.forward()
    end
    if (mABN(name)) then return true end
    t.digUp()
    t.up()
    
    -- Mine back wall
    if (mineWall(radius, mABN, {name})) then return true end
    
    -- Mine all rings
    turnR(2)
    for i=1,(radius*2)-1 do
        t.dig()
        t.forward()
        if(mineRing(radius, mABN, {name})) then return true end
    end
    
    -- Mine last wall
    t.dig()
    t.forward()
    if(mineWall(radius, mABN, {name})) then return true end
    
    turnR(2)
    
    -- If we didn't find it 
    return false
    
end

-- Dumps inventory into ender chest
-- in first available block spot
-- Fails if no available space
-- ret1: success bool
function dumpInv()
    -- Find direction to dump in
    turns = turnX()
    if (turns > -1) then    
        t.select(16)
        t.place()
        for i=1,13 do
            t.select(i)
            t.drop()
        end
        t.select(16)
        t.dig()
        t.select(1)
        -- Return to same direction as before
        turnL(turns)
        return true
    end
    return false
end

-- Places charger and flux point
-- ret1: success bool
function refuel()
    -- Place point
    t.select(14)
    t.dig()
    t.forward()
    t.digDown()
    t.placeDown()
    t.back()
    -- Place charger
    t.digDown()
    t.select(15)
    t.placeDown()
    while(t.getFuelLevel() < t.getFuelLimit()) do
        sleep(0.2)
    end
    -- Dig charger
    t.digDown()
    -- Dig point
    t.select(14)
    t.drop()
    t.forward()
    t.digDown()
    t.back()
    return true    
end