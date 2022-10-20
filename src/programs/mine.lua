require(settings.get("ghu.base") .. "core/apis/ghu")
require("miningLib")

function init()
    res, items = sortReqs()

    if (not(res)) then 
        print("Missing these items:")
        for k,v in pairs(missing) do
            print(k)
        end
        print("Trying to find them in the surroundings...")
        res = mineByName(items, 1, true)
        if (res) then
            return select(1, sortReqs())
        end     
    end
    return true
end

print("Initializing...")
if (init()) then
    print("Successfully Initialized!")
else
    error("Init failed")
end

-- Refuel if needed
function checkFuel()
    if (t.getFuelLevel() < t.getFuelLimit() * 0.5) then
        refuel()
    end
end

-- Empty inv if less than 4 empty slots
function checkInv()
    if (getNumEmpty() < 4) then
        dumpInv()
    end
end

-- Check both inv and fuel
function checkInvAndFuel()
    checkInv()
    checkFuel()
end


-- Dig wall 5x5
function digWall5()
    mineWall(2)
end

while (true) do
    chain(digWall5, checkInvAndFuel, t.dig, t.forward)
end