local routing = require("helpers.routing")

local Hash_station = require("helpers.hash_station")

local teleport = {}

---Initiate teleport
---@param sender integer
---@param payload {station_hash: string} | {destination: Station | ccTweaked.Vector}
---@param external boolean
---@return boolean
function teleport.initiate(sender, payload, external)
    if external then
        
        return true
    else
        LOGGER:info("Initiating teleport from " .. tostring(get_this_station()) .. " to " .. tostring(payload.destination))
        local route = routing.find_route(get_this_station(), payload.destination, get_stations())
        
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