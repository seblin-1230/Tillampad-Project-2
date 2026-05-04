local routing = require("helpers.routing")

local Hash_station = require("helpers.hash_station")

local teleport = {}

---Initiate teleport
---@param sender integer
---@param payload string[] | {destination: Station | ccTweaked.Vector}
---@param external boolean
---@return boolean sucess
---@return string? error
function teleport.initiate(sender, payload, external)
    if external then
        LOGGER:info(payload[1])
        LOGGER:info(payload[2])
        return true
    else
        LOGGER:info("Initiating teleport from " .. tostring(get_this_station()) .. " to " .. tostring(payload.destination))
        local route = routing.find_route(get_this_station(), payload.destination)
        
        if #route == 0 then
            return false, "No route found"
        end
        table.remove(route, #route)
        local destination = table.remove(route, #route)

        local this_station_hash, nonce = Hash_station(os.computerID(), get_this_station().station_id)
        
        LOGGER:info("Sending to: " .. tostring(get_stations()[destination].computer_id))
        LOGGER:info(this_station_hash .. ", " .. nonce)
        encnet.send(get_stations()[destination].computer_id, "TeleInit", this_station_hash, nonce)

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