local Hash_station = require("helpers.hash_station")

local teleport = {}

---Initiate teleport
---@param sender integer
---@param payload {station_hash: string} | {}
---@param external boolean
---@return boolean
function teleport.initiate(sender, payload, external)
    if external then
        
        return true
    else
        local station_hash = Hash_station(os.computerID())
        return true
    end
end

function teleport.verification(sender, payload, external)
    if external then
        
        return true
    else

    end
end

function teleport.denied(sender, payload, external)
    if external then
        
        return true
    else

    end
end

function teleport.done(sender, payload, external)
    if external then
        
        return true
    else

    end
end

return teleport