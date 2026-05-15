local routing = require("helpers.routing")

local Hash_station = require("helpers.hash_station")

local teleport = {}

local function do_teleport(sender)
    print("Teleported to " .. tostring(_G.destination))
    LOGGER:info("Teleported to " .. tostring(_G.destination))

    
    if sender ~= os.computerID() then 
        LOGGER:info("Sending route: " .. textutils.serialise(_G.route, { compact = true }) ..
        " length: " .. tostring(#_G.route))
        encnet.send(sender, "TeleDone", table.unpack(_G.route))
    end
    _G.destination = nil
    _G.route = nil
end

local function teleport_continue()
    _G.destination = table.remove(_G.route, #_G.route)
    LOGGER:info("Continuing teleport from " .. tostring(get_this_station()) .. " to " .. tostring(_G.destination))

    if _G.destination == nil then
        LOGGER:error("Destination nil aborting")
        error("Destination nil")
    end

    if type(_G.destination) == "table" then
        do_teleport(os.getComputerID())
        LOGGER:info("Teleporting user to " .. textutils.serialise(_G.destination))
        LOGGER:info("Teleport chain done")
        return
    end

    local hash_this_this, nonce = Hash_station(os.computerID())

    LOGGER:info("Sending teleport request to: " .. tostring(get_stations()[_G.destination]))
    LOGGER:info("With hash: " .. hash_this_this .. ", " .. nonce)
    encnet.send(_G.destination, "TeleInit", hash_this_this, nonce)
end

---Initiate teleport
---@param sender integer
---@param payload string[] | {destination: Station | ccTweaked.Vector}
---@param external boolean
---@return boolean sucess
---@return string? error
function teleport.initiate(sender, payload, external)
    if external then
        LOGGER:info("Initiating teleport with: " .. tostring(sender))
        local hash_other_other = payload[1]
        local hash_nonce = payload[2]

        local hash_other_this = Hash_station(sender, hash_nonce)

        if hash_other_other ~= hash_other_this then
            LOGGER:warning("Teleport rejected, mismatched station hash")
            encnet.send(sender, "TeleDeni")
            teleport.denied(os.computerID())
            return true
        end

        teleport.verification(sender, { hash_nonce }, false)

        return true
    else
        LOGGER:info("Initiating teleport from " ..
        tostring(get_this_station()) .. " to " .. tostring(payload.destination))
        _G.route = routing.find_route(get_this_station(), payload.destination)

        if #_G.route == 0 then
            return false, "No route found"
        end

        LOGGER:info("Route: " .. textutils.serialise(_G.route, { compact = true }))

        table.remove(_G.route, #_G.route)
        _G.destination = table.remove(_G.route, #_G.route)

        LOGGER:info("Route (destination removed): " .. textutils.serialise(_G.route, { compact = true }))

        local hash_this_this, nonce = Hash_station(os.computerID())

        LOGGER:info("Sending teleport request to: " .. tostring(get_stations()[_G.destination]))
        LOGGER:info("With hash: " .. hash_this_this .. ", " .. nonce)
        encnet.send(_G.destination, "TeleInit", hash_this_this, nonce)

        return true
    end
end

---Verify the station being teleported to
---@param sender integer
---@param payload string[]
---@param external boolean
---@return boolean
function teleport.verification(sender, payload, external)
    if external then
        LOGGER:info("Externaly called verifing station " .. tostring(sender))
        local hash_other_other = payload[1]
        local hash_nonce = payload[2]

        local hash_other_this = Hash_station(sender, hash_nonce)

        if hash_other_other ~= hash_other_this then
            LOGGER:warning("Teleport rejected, mismatched station hash")
            encnet.send(sender, "TeleDeni")
            teleport.denied(os.computerID())
            return true
        end

        LOGGER:info("Station " .. tostring(sender) .. " safe, teleporting")
        do_teleport(sender)

        return true
    else
        LOGGER:info("Start verifing station " .. tostring(sender))
        local hash_nonce = payload[1]
        local hash_this_this = Hash_station(os.computerID(), hash_nonce)
        encnet.send(sender, "TeleVeri", hash_this_this, hash_nonce)
        return true
    end
end

function teleport.denied(sender, payload, external)
    if external then
        LOGGER:error("Teleport denied.")
        get_stations()[_G.destination].unsafe = true
        return true
    else
        LOGGER:warning("Teleport unsafe, marking " .. tostring(_G.destination) .. " as unsafe. Retrying teleport")
        teleport.initiate(os.computerID(), { destination = _G.route[1] }, false)
        return false
    end
end

---Sent when teleport done
---@param sender integer
---@param payload string[]
---@param external boolean
---@return boolean
function teleport.done(sender, payload, external)
    if external then
        _G.route = {}

        LOGGER:info("Rebuilding route")
        LOGGER:info(textutils.serialise(payload, {compact=true}))
        for i = 1, #payload do
            if payload[i]:sub(1, 1) == "v" then
                local split = {}
                for str in string.gmatch(payload[i]:gsub("v", ""), "[^,]+") do
                    table.insert(split, tonumber(str))
                end
                
                local vec = vector.new(split[1], split[2], split[3])

                LOGGER:info(string.format("Item %d: Vector %s", i, tostring(vec)))
                _G.route[i] = vec
            else
                LOGGER:info(string.format("Item %d: Station %s", i, payload[i]))
                _G.route[i] = tonumber(payload[i])
            end
        end

        LOGGER:info("Rebuilt route: " .. textutils.serialise(_G.route, { compact = true }))

        teleport_continue()

        return true
    else
        local source = debug.getinfo(2, "Sl").source:gsub("^@", "")
        LOGGER:error("Teleport done called from " + source)
        return true
    end
end

return teleport
