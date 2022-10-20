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

function recoverReq(name)
    
end

print("Initializing...")
if (init()) then
    print("Successfully Initialized!")
else
    error("Init failed")
end

while (true) do turnL(10) end

while (true) do
    t.forward()
    print("Dumping Inv")
    if (dumpInv()) then
        print("Success")
    else
        print("Failed")
    end
    print("FuelLevel: ", t.getFuelLevel())
    print("Refueling")
    if (refuel()) then
        print("Success")
    else
        print("Failed")
    end
    print("FuelLevel: ", t.getFuelLevel())
end