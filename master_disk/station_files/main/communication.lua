---@alias PayloadType "TeleInit" | "TeleVeri" | "TeleDeni" | "TeleDone" | "TeleWait" | "TeleQueu" | "SeKeyReq" | "SeKeyRes" | "ClearMas" | "NewStati" | "OtheStat"

local function handle_communication(master_key)
    local new_station = require("main.new_station")
    local teleport = require("main.teleport")

    local function_table = {
        TeleInit = teleport.initiate,
        TeleVeri = teleport.verification,
        TeleDeni = teleport.denied,
        TeleDone = teleport.done,
        TeleWait = teleport.wait,
        TeleQueu = teleport.queue,
        NewStati = new_station.new_station,
        OtheStat = new_station.get_other_stations
    }

    encnet.open("left", master_key)

    while true do
        local sender, payload_type, payload = assert(encnet.receive())

        --LOGGER:info("Comm recived; Type: " .. payload_type)
        os.queueEvent(payload_type, sender, payload)
        local sucess = function_table[payload_type](sender, payload, true)


        if not sucess then
            --LOGGER:error(string.format("Invalid comm; sender: %d; message type: %s; payload: %s", sender, payload_type,
            --    textutils.serialise(payload)))
        end
    end
end

local function wait_for(payload_type, sender, timeout)
    -- --LOGGER:info("Wait for called, type: " .. payload_type)
    local sucess = true

    if timeout ~= nil then
        parallel.waitForAny(
            function()
                repeat
                    local event, fn_sender, payload = os.pullEvent(payload_type)
                    if sender == nil then sender = fn_sender end
                until fn_sender == sender
            end,
            function()
                os.sleep(timeout)
                sucess = false
            end
        )
    else
        repeat
            local event, fn_sender, payload = os.pullEvent(payload_type)
            --LOGGER:info(payload_type .. " recived")
            if sender == nil then sender = fn_sender end
        until fn_sender == sender
    end

    return sucess
end

return { Handle_communication = handle_communication, wait_for = wait_for }
